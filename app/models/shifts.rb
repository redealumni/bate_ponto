# Plain class for dealing with shifts in a week
# Meant to be serialized in the users table
class Shifts

  # Mappings
  DAY_MAPPING = {
    monday: 1,
    thursday: 2,
    wednesday: 3,
    tuesday: 4,
    friday: 5
  }

  NUM_MAPPING = {
    1 => :monday,
    2 => :thursday,
    3 => :wednesday,
    4 => :tuesday,
    5 => :friday
  }

  # Allowed keys in the class
  VALID_DAYS = Set.new(DAY_MAPPING.keys)

  def self.default_shifts
    [Shift.new(480, 720, 0), Shift.new(840, 1080, 0)]
  end

  def self.new_default
    values = {}
    VALID_DAYS.each { |day| values[day] = self.default_shifts }
    self.new values
  end

  def initialize(shifts = {})
    @days = {}
    VALID_DAYS.each { |key| @days[key] = [] }
    shifts.each { |key, value| @days[key] = value }
    @days = @days.keep_if { |key, value| VALID_DAYS.member? key }
  end

  def [](key)
    @days[key]
  end

  def num_of_shifts(key)
    @days[key].size
  end

  def lunch_time(key = nil)
    if key.nil?
      @days.map { |day|
        day.map { |s| s.lunch }.sum
      }.sum
    else
      @days[key].map { |s| s.lunch }.sum
    end
  end

  # Check if shifts are valid
  def valid?
    @days.each_value do |day|
      day.sort!
      day.each_cons(2) { |s1, s2| return false unless s1 < s2 and s1.valid? }
      return false unless day.last.valid?
    end
    return true
  end

end