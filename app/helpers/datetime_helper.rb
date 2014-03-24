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

  # Starting from a initial date, find a date evaluating a condition
  # from a block
  def find_date(initial_date)
    result = initial_date

    loop do
      status = yield result
      break if status

      result += 1.day
    end

    return result
  end

  def get_monday_of_week(date)
    find_date(date.beginning_of_week) { |day| day.cwday == 1 }
  end

  def get_first_monday_of_month(date)
    find_date(date.beginning_of_month) { |day| day.cwday == 1 }
  end

  def get_friday_of_week(date)
    find_date(date.beginning_of_week) { |day| day.cwday == 5 }
  end

  def get_first_weekday_of_month(date)
    find_date(date.beginning_of_month) { |day| day.cwday <= 5 }
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

  # Format a amount of minutes as a readable string of hours:minutes
  def readable_duration(minutes)
    h = minutes / 60
    m = minutes % 60
    str_hours = if h > 0 then (h.to_s + 'h') else '' end
    str_minutes = if m > 0 then (m.to_s + 'm') else '' end

    if str_hours.blank? and str_minutes.blank? then '0m'
    elsif str_hours.blank? then str_minutes
    elsif str_minutes.blank? then str_hours
    else str_hours + ':' + str_minutes end
  end

end