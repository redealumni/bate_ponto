# encoding: utf-8
class User < ActiveRecord::Base
  
  TOLERANCE = 0.5 # hours

  scope :by_name, -> { order 'name ASC' }
  scope :visible, -> { where 'hidden = ?', false }
  scope :hidden, -> { where 'hidden = ?', true}
  
  # has_secure_password enables password confirmation and presence,
  # since we already set to validate presence manually and we don't need
  # password confirmation we just tell the method to enable no validation
  has_secure_password validations: false

  validates :password, presence: { on: :create }
  has_many :punches

  def first_shift
    # TODO: implement
    [8, 12]
  end

  def second_shift
    # TODO: implement
    [14, 18]
  end

  def num_of_shifts
    # TODO: implement
    2
  end

  def is_hours_ok(hours)
    return (hours - self.daily_goal).abs < TOLERANCE
  end

  def hours_error(hours)
    return (hours - self.daily_goal)
  end

  def is_punch_time_ok(punch_time, shift, moment)
    # TODO: implement
    return true
  end

  # Return as a integer in minutes
  def punch_time_error(punch_time, shift, moment)
    # TODO: implement
    return 0
  end

  # Return as a integer in hours
  def daily_goal
    # TODO: implement
    return 8
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

  def report
    "report!"
  end
  
end
