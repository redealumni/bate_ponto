module DatetimeHelper
  module_function
  
  # Given a date range, return one such that ignores future dates if applicable
  def ignore_future(date_range)
    if date_range.begin > Date.today
      nil
    elsif date_range.end > Date.today
      date_range.begin..Date.today
    else
      date_range
    end
  end

  # Given a date range, return it's size
  def date_range_size(date_range)
    (date_range.end.to_date - date_range.begin.to_date).to_i + 1
  end

  # Given a date range, return a time range starting from midnight of the begin,
  # up to the end of the last day
  def to_time_range(date_range)
    date_range.begin.beginning_of_day..date_range.end.end_of_day
  end

  # Return a datetime range for the beginning to the end of the day
  def range_for_day(date)
    date.beginning_of_day..date.end_of_day
  end

  def get_monday_of_week(date)
    if date.cwday == 5
      date
    else
      date + (1 - date.cwday).days
    end
  end

  def get_first_monday_of_month(date)
    start_point = date.beginning_of_month

    first_try = get_monday_of_week(start_point)
    if first_try.month == start_point.month
      first_try
    else
      first_try + 7.days
    end
  end

  def get_friday_of_week(date)
    if date.cwday == 5
      date
    else
      date + (5 - date.cwday).days
    end
  end

  def get_first_weekday_of_month(date)
    start_point = date.beginning_of_month
    if start_point.cwday >= 1 and start_point.cwday <= 5
      start_point
    else
      start_point + (8 - start_point.cwday).days
    end
  end

  # Get array with day ranges flattened as days
  def get_days_for_ranges(day_ranges_arrays)
    day_ranges_arrays.map(&:to_a).flatten!
  end

  # Get array with ranges representing weeks between two dates
  def get_weeks_of_range(date_range)
    start = get_monday_of_week(date_range.begin)
    result = []

    ini = start
    fin = nil
    loop do
      fin = get_friday_of_week(ini)
      result << (ini..fin)
      ini += 1.week

      break if ini > date_range.end
    end

    return result
  end

  # Get array with ranges representing weeks of the month
  # Include partial weeks
  def get_weeks_of_month(date)
    start = get_first_monday_of_month(date)

    result = []

    first_weekday = get_first_weekday_of_month(start)
    if first_weekday != start then
      result << (first_weekday..get_friday_of_week(first_weekday))
    end

    (0..4).each do |i|
      week_start = start + i.weeks
      result << (week_start..get_friday_of_week(week_start))
    end

    if result.last.begin.mon != start.mon then 
      result.pop
    elsif result.last.end.mon != start.mon then 
      result[-1] = result.last.begin..start.end_of_month 
    end

    return result
  end

  # Format a amount of seconds as a readable string of hours:minutes:seconds
  def readable_duration(total_seconds)
    neg = total_seconds < 0
    total_seconds = total_seconds.abs

    prefix = neg ? '- ' : ''

    s = total_seconds % 60
    m = (total_seconds / 60) % 60
    h = total_seconds / (3600)

    str_hours   = h > 0 ? (h.to_s + 'h') : '' 
    str_minutes = m > 0 ? (m.to_s + 'm') : '' 
    str_seconds = s > 0 ? (s.to_s + 's') : ''

    prefix + [str_hours, str_minutes, str_seconds].select(&:present?).join(':')
  end

  # Convert a amount of seconds to a fixed format string
  def duration(total_seconds)
    neg = total_seconds < 0
    total_seconds = total_seconds.abs

    prefix = neg ? '- ' : ''

    s = total_seconds % 60
    m = (total_seconds / 60) % 60
    h = total_seconds / (3600)

    format("%02d:%02d:%02d", h, m, s)
  end

end