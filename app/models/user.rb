class User < ActiveRecord::Base

  DEFAULT_SHIFTS = [480, 720, 0, 840, 1080, 0]
  
  # TODO: clean up how hours are calculed
  TOLERANCE_HOURS = 0.5 # hours
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
    record.errors.add(attr, "possuí formato inválido.") unless value.valid?
  end

  # We also put daily goals as arrays of hours (in minutes) in the database
  serialize :goals, Array
  validates_each :goals do |record, attr, value|
    record.errors.add(attr, "possuí formato inválido.") unless record.flexible_goal or value.size == 5
  end

  # Ensure shifts and goals aren't nil
  before_validation do |user|
    self.shifts ||= Shifts.new_default
    self.goals ||= ([8] * 5)
  end

  # Get weekly goal
  def weekly_goal(range = nil)
    if range then self.goals[range].sum else self.goals.sum end
  end

  # Get daily goal
  def daily_goal(day)
    self.goals[Shifts::DAY_MAPPING[day] - 1]
  end

  # Given a amount of hours and the weekday, check if it's ok for this user
  def is_hours_ok(day, hours)
    return self.flexible_goal || (hours - self.daily_goal(day)).abs < TOLERANCE_HOURS
  end

  # Return how off is the hours for this user in hours (float)
  def hours_error(day, hours)
    return (hours - self.daily_goal(day))
  end

  # Given a timestamp of a punch, check if it's ok for this user
  def is_punch_time_ok(punch_time, day, shift_num, moment)
    return true if self.flexible_goal

    adjusted_time = shifts[day][shift_num].shift_time punch_time, moment
    return (adjusted_time - punch_time).abs < TOLERANCE_PUNCH
  end

  # Return as a integer, in minutes
  def punch_time_error(punch_time, day, shift_num, moment)
    adjusted_time = shifts[day][shift_num].shift_time punch_time, moment
    return ((adjusted_time - punch_time) / 60).round
  end

  def working?
    if last_punch = self.punches.order('punched_at DESC').first
      last_punch.entrance?
    else
      false
    end
  end

  def hours_since_last_state
    if last_punch = self.punches.order('punched_at DESC').first
      (Time.now - last_punch.punched_at)/60/60
    else
      0
    end
  end

  def hours_today
    self.hours_worked(Time.now.beginning_of_day..Time.now)
  end

  def hours_worked_in_month(month)
    beginning_of_month = month.beginning_of_month.midnight
    end_of_month = month.end_of_month.end_of_day

    self.hours_worked(beginning_of_month..end_of_month)
  end

  # TODO: read ** CAREFULLY ** later, looks like a good place to refactor
  def hours_worked(datetime_range)
    # don't consider future time
    datetime_range = datetime_range.begin..(datetime_range.end < Time.now ? datetime_range.end : Time.now)
    
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
    
    time_worked/60/60
  end
  
  def bad_memory?
    if self.bad_memory_index > 50
      true
    else
      false
    end
  end
  
  def bad_memory_index
    last_punches = self.punches.order('punched_at DESC').limit(10)
    num_altered = last_punches.inject(0) {|count, p| p.altered? ?  count + 1 : count}
    num_altered.to_f / last_punches.count * 100 rescue 0
  end
  
end
