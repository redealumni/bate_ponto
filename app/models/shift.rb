# Class representing a single shift - entrance and exit are given in minutes after midnight
# Lunch time is a duration in minutes
Shift = Struct.new(:entrance, :exit, :lunch) do
  include Comparable

  # Given day and moment, get a time representing the actual shift moment
  def shift_time(time, moment)
    time.midnight + self[moment].minutes
  end

  # Get readable form for shift
  def to_s
    formatted = [:entrance, :exit].map { |m| I18n.l shift_time(Time.zone.now, m), format: :just_time }
    formatted.join(' as ') + if lunch > 0 
      " com #{DatetimeHelper.readable_duration(lunch.minutes)} de intervalo"
    else
      ""
    end
  end

  # Check if shift is valid
  def valid?
    entrance < exit && lunch < exit - entrance
  end

  # Comparator
  def <=>(other)
    entrance <=> other.entrance
  end

  # Populate from hash
  def from_hash(data)
    data.each { |k, v| self[k] = v }
    self
  end

  # Class variant of from_hash
  def self.from_hash(data)
    self.new.from_hash data
  end

end