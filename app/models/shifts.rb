# Plain class for dealing with shifts in a week
# Meant to be serialized in the users table
class Shifts

  include Enumerable
  extend Forwardable

  # Mappings
  DAY_MAPPING = {
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }

  NUM_MAPPING = {
    1 => :monday,
    2 => :tuesday,
    3 => :wednesday,
    4 => :thursday,
    5 => :friday,
    6 => :saturday
  }

  # Allowed keys in the class
  VALID_DAYS = Set.new(DAY_MAPPING.keys)

  def self.default_shifts
    [Shift.new(540, 720, 60), Shift.new(780, 1080, 0)]
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
  def from_hash(data, only_first = false)
    if only_first
      first = data.first.last.map { |e| Shift.from_hash e }
      VALID_DAYS.each do |sym|
        @days[sym] = first
      end
    else
      data.each do |day, shifts|
        @days[day.to_sym] = shifts.map { |e| Shift.from_hash e }
      end
    end
    self
  end

  # Class instance variant of from_hash
  def self.from_hash(data, only_first = false)
    Shifts.new.from_hash data, only_first
  end

  # TODO: rip this out
  def self.localize(day)
    I18n.translate('date.day_names')[DAY_MAPPING[day]]
  end

end
