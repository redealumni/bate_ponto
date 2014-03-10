module DatetimeHelper
  module_function
  
  # Given a date range, return it's size
  def date_range_size(date_range)
    (date_range.end.to_date - date_range.begin.to_date).to_i + 1
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

  def get_first_monday_of_month(date)
    find_date(date.beginning_of_month) { |day| day.cwday == 1 }
  end

  def get_friday_of_week(date)
    find_date(date.beginning_of_week) { |day| day.cwday == 5 }
  end

  def get_first_weekday_of_month(date)
    find_date(date.beginning_of_month) { |day| day.cwday <= 5 }
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
    hours = if h > 0 then (h.to_s + "h:") else "" end
    return hours + (minutes % 60).to_s + "m"
  end

end