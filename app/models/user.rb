class User < ActiveRecord::Base
  include SlackNotifierHelper

  DEFAULT_SHIFTS = [480, 720, 0, 840, 1080, 0]
  TOLERANCE_HOURS = 30.minutes
  TOLERANCE_PUNCH = 15.minutes

  scope :by_name, -> { order 'name ASC' }
  scope :visible, -> { where 'hidden = ?', false }
  scope :hidden, -> { where 'hidden = ?', true}


  # has_secure_password enables password confirmation and presence,
  # since we already set to validate presence manually and we don't need
  # password confirmation we just tell the method to enable no validation
  has_secure_password validations: false
  validates :password, presence: { on: :create }

  has_many :punches

  # Each user has shifts, entrance and exit times, and lunch hours. We don't need to query these (for now, anyway),
  # so we serialize it back and forth as the Shifts class
  serialize :shifts
  validates_each :shifts do |record, attr, value|
    record.errors.add(attr, "possui formato inválido.") unless value.valid?
  end

  # We also put daily goals as arrays of hours (in minutes) in the database
  serialize :goals, Array
  validates_each :goals do |record, attr, value|
    record.errors.add(attr, "possui formato inválido.") unless record.flexible_goal or value.size == 6
  end

  # Ensure shifts and goals aren't nil
  before_validation do |user|
    self.shifts ||= Shifts.new_default
    self.goals  ||= ([8] * 5).push(0)
  end


  # Get weekly goal
  def weekly_goal(range = nil)
    (range.present? ? self.goals[range].sum : self.goals.sum).hours
  end

  # Get daily goal
  def daily_goal(day)
    self.goals[Shifts::DAY_MAPPING[day] - 1].try(:hours) || 0
  end

  # Given a amount of time and the weekday, check if it's ok for this user
  def is_time_ok(day, time)
    return self.flexible_goal || (time - self.daily_goal(day)).abs < TOLERANCE_HOURS
  end

  # Return how off is the time for this user in time
  def time_error(day, time)
    return (time - self.daily_goal(day))
  end

  # Given a timestamp of a punch, check if it's ok for this user
  def is_punch_time_ok(punch_time, day, shift_num, moment)
    return true if self.flexible_goal

    adjusted_time = shifts[day][shift_num].shift_time punch_time, moment
    return (adjusted_time - punch_time).abs < TOLERANCE_PUNCH
  end

  # Return as a integer, in seconds
  def punch_time_error(punch_time, day, shift_num, moment)
    adjusted_time = shifts[day][shift_num].shift_time punch_time, moment
    return ((punch_time - adjusted_time) / 60)
  end

  def working?
    if last_punch = self.punches.latest.first
      last_punch.entrance?
    else
      false
    end
  end

  def time_since_last_state
    if last_punch = self.punches.latest.first
      (Time.zone.now - last_punch.punched_at)
    else
      0
    end
  end

  def time_worked_today
    self.time_worked(Time.zone.now.beginning_of_day..Time.zone.now)
  end

  def time_worked_in_month(month)
    beginning_of_month = month.beginning_of_month.midnight
    end_of_month = month.end_of_month.end_of_day

    self.time_worked(beginning_of_month..end_of_month)
  end

  # TODO: read ** CAREFULLY ** later, looks like a good place to refactor
  def time_worked(datetime_range)
    # don't consider future time
    datetime_range = datetime_range.begin..(datetime_range.end < Time.zone.now ? datetime_range.end : Time.zone.now)

    # Rails 4: Relation#all deprecated - just give the relationship itself
    punches_in_range = self.punches.where('punched_at >= ? and punched_at <= ?', datetime_range.begin, datetime_range.end).
      order('punched_at ASC')

    return 0 if punches_in_range.blank?

    fixed_punches_in_range = []

    # adds punches that may be missing in the middle
    punches_in_range.each_cons(2) do |ps|
      p1, p2 = ps
      fixed_punches_in_range << p1
      if p1.entrance == p2.entrance #next punch is not right, add one in between
        fixed_punches_in_range << Punch.new(punched_at: p2.punched_at, entrance: !p2.entrance?)
      end
    end

    # add last punch from range, which the loop didn't catch
    fixed_punches_in_range << punches_in_range.last

    # add punches to the edges, if appropriate
    if not fixed_punches_in_range.first.entrance?
      fixed_punches_in_range.unshift Punch.new(punched_at: datetime_range.begin)
    end
    if fixed_punches_in_range.last.entrance?
      fixed_punches_in_range << Punch.new(punched_at: datetime_range.end)
    end

    time_worked = 0
    fixed_punches_in_range.each_slice(2) do |pair|
      time_worked += pair.last.punched_at - pair.first.punched_at
    end

    time_worked.to_i
  end

  def bad_memory?
    if self.bad_memory_index > 50
      true
    else
      false
    end
  end

  def bad_memory_index
    last_punches = self.punches.latest.limit(10)
    num_altered = last_punches.inject(0) {|count, p| p.altered? ?  count + 1 : count}
    num_altered.to_f / last_punches.count * 100 rescue 0
  end

  # checks if user is late for that shift
  def late?(shift)
    return false if self.flexible_goal
    # User didn't accomplish daily goal yet
    if self.time_worked_today/60 < self.daily_goal(DatetimeHelper.todays_day)/60
      lunch = self.shifts[DatetimeHelper.todays_day][shift].try(:lunch)
      minutes_late = (self.punches.latest.first.punched_at - (Date.today.beginning_of_day+self.shifts[DatetimeHelper.todays_day][shift].entrance.minutes+lunch))/60
      minutes_late = minutes_late.to_i
      if minutes_late > 0 && minutes_late <= 10
        is_late_notification(self.name,minutes_late)
        return true
      end
      if minutes_late > 10
       missed_today_notification(self.name,minutes_late)
      end
    end
  end

  # gets user's closest shift
  def closest_shift
    first_shift = (Time.zone.now - (Date.today.beginning_of_day + self.shifts[DatetimeHelper.todays_day][0].entrance.minutes))/60
    second_shift = (Time.zone.now - (Date.today.beginning_of_day + self.shifts[DatetimeHelper.todays_day][1].entrance.minutes))/60
    if first_shift.abs <= second_shift.abs || self.first_punch_of_day?
      return 0
    else
      return 1
    end
  end

  def missed_the_day?(day)
    # TODO: The following condition will eventually change when bate_ponto application implements rules to treat weekend days
    if self.flexible_goal || day.strftime("%A").downcase == "sunday" || day.strftime("%A").downcase == "saturday"
      return false
    end
    day_range = DatetimeHelper.range_for_day(day)
    if self.time_worked(day_range) == 0
      missed_the_day_notification(self.name, day)
      return true
    else
      return false
    end
  end

  def forgot_punch?
    last_punch = self.punches.latest.first
    if last_punch.entrance
      if Time.zone.now.to_time - last_punch.punched_at > 39600
        forgot_punch_notification(self.name, self.slack_username)
      end
    end
  end

  def first_punch_of_day?
    return true if self.punches.where("punched_at > ?", Time.zone.today.beginning_of_day).count == 1
  end

  def break_too_long?
    if !self.first_punch_of_day?
      first_punch_out = self.punches.where("punched_at > ? AND entrance = ?", Time.zone.today.beginning_of_day,false).first.punched_at
      last_punch_in   = self.punches.where("punched_at > ? AND entrance = ?", Time.zone.today.beginning_of_day,true).last.punched_at
      if  ((last_punch_in - first_punch_out)/60).to_i > self.shifts[DatetimeHelper.todays_day][0].lunch.to_i
        minutes_exceeded = ((last_punch_in - first_punch_out)/60).to_i - self.shifts[DatetimeHelper.todays_day][0].lunch.to_i
        break_too_long_notification(self.name,minutes_exceeded)
      end
    end
  end

  def get_full_weeks_of_month(date)
    month_range = date.beginning_of_month..date.end_of_month
    month_range.chunk { |d| d.wday > 0 }.select(&:first).map(&:last)
  end
  def time_worked_at_date(date)
    self.time_worked(date.beginning_of_day..date.end_of_day)
  end 

end
