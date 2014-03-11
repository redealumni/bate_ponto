# encoding: utf-8
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
  # so we serialize it back and forth as a array of integers representing the shift hours in minutes
  # from midnight
  serialize :shifts, Array
  validates_each :shifts do |record, attr, value|
    if value.blank?
      record.errors.add(attr, "não pode ser vazio.")
    elsif value.size % 3 != 0
      record.errors.add(attr, "possuí formato inválido.")
    else
      grouped = value.each_slice(3).map { |s| s }
      grouped.each_cons(2) do |cons|
        if cons[0][0] > cons[0][1] or cons[0][1] > cons[1][0] or cons[1][0] > cons[1][1] then
          record.errors.add(attr, "possuí formato inválido.")
          break
        end
      end
    end 
  end

  # Get the entrance, exit and lunch times of a shift as an array
  # If no argument passed, return all times grouped by shift
  def shift(num = nil)
    if num.nil?
      self.shifts.each_slice(3).map { |s| s }
    else
      # positions 0 to 2 for first shift, 3 to 5 for second, etc
      self.shifts[(num - 1) * 3, 3]
    end
  end

  def num_of_shifts
    self.shifts.size / 3
  end

  # Given a amount of hours, check if it's ok for this user
  def is_hours_ok(hours)
    return (hours - self.daily_goal).abs < TOLERANCE_HOURS
  end

  # Return how off is the hours for this user in hours (float)
  def hours_error(hours)
    return (hours - self.daily_goal)
  end

  # Convenience hash so we can use meaningful symbols for the next three
  # methods
  MOMENTS = {
    entrance: 0,
    exit: 1
  }

  # Given shift and a day, get a datetime representing the actual shift moment
  def shift_time(time, shift_num, moment)
    time.midnight + self.shift(shift_num)[MOMENTS[moment]].minutes
  end

  # Get readable form for shift
  def readable_shift(num)
    formatted = MOMENTS.each_key.map { |key| I18n.l self.shift_time(Time.now, num, key), format: :just_time }
    lunch = self.shift(num).last
    formatted.join(' as ') + if lunch > 0 
      " com #{DatetimeHelper.readable_duration(lunch)} de intervalo"
    else
      ""
    end
  end

  # Given a timestamp of a punch, check if it's ok for this user
  def is_punch_time_ok(punch_time, shift_num, moment)
    adjusted_time = shift_time punch_time, shift_num, moment
    return (adjusted_time - punch_time).abs < TOLERANCE_PUNCH
  end

  # Return as a integer, in minutes
  def punch_time_error(punch_time, shift_num, moment)
    adjusted_time = shift_time punch_time, shift_num, moment
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
    beginning_of_month = month.beginning_of_month
    end_of_month = month.end_of_month

    self.hours_worked(beginning_of_month..end_of_month)
  end
  
  # TODO: read carefully later, looks like a good place to refactor
  def hours_worked(datetime_range)
    #don't consider future time
    datetime_range = datetime_range.begin..(datetime_range.end < Time.now ? datetime_range.end : Time.now)
    
    # Rails 4: Relation#all deprecated, using to_a instead
    punches_in_range = self.punches.where('punched_at >= ? and punched_at <= ?', datetime_range.begin, datetime_range.end).
      order('punched_at ASC').to_a
    
    return 0 if punches_in_range.empty?

    fixed_punches_in_range = []

    #adds punches that may be missing in the middle
    punches_in_range.each_with_index do |p, i|
      fixed_punches_in_range << p
      next_punch = punches_in_range[i+1]
      if next_punch and next_punch.entrance == p.entrance #next punch is not right, add one in between
        fixed_punches_in_range << Punch.new(punched_at:  next_punch.punched_at, entrance: !next_punch.entrance?)
      end
    end

    #add punches to the edges, if appropriate
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
