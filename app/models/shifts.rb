# Plain class for dealing with shifts in a week
# Meant to be serialized in the users table
class Shifts

  include Enumerable
  extend Forwardable

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

  # Delegate iterators and acessors to internal hash
  def_delegators :@days, :[], :each, :each_value, :each_key

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

  # Populate from hash
  def from_hash(data)
    data.each do |day, shifts|
      @days[day.to_sym] = shifts.map { |e| Shift.from_hash e }
    end
    self
  end

  # Class instance variant of from_hash
  def self.from_hash(data)
    Shifts.new.from_hash data
  end

  # TODO: rip this out
  def self.localize(day)
    I18n.translate('date.day_names')[DAY_MAPPING[day]]
  end

end
