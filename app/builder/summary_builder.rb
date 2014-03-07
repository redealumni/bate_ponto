module SummaryBuilder

  def range_for_day(date)
    date.beginning_of_day..date.end_of_day
  end

  # hours
  TOLERANCE = 0.5

  Week = Struct.new(:name, :hours, :daily_goal, :week_size) do
    def problem?
      (weekly_goal - hours).abs < TOLERANCE * week_size
    end

    def weekly_goal
      daily_goal * week_size
    end

  end

  Day = Struct.new(:date, :hours, :punches, :issue) do
    def readable_punches
      punch_times = punches.map { |p| I18n.l p.punched_at, format: :just_time }
      result = []
      punch_times.each_slice(2) { |slice| result << slice.join(" as ") }
      result.join(", ")
    end

  end

  Summary = Struct.new(:user, :date, :weeks, :days, :chart)

  def week_size(week_range)
    count = 0

    week_range.each do
      count += 1
    end

    return count
  end

  def select_date(initial_date)
    result = initial_date

    loop do
      status = yield result
      break if status

      result += 1.day
    end

    return result
  end

  def get_first_monday_of_month(date)
    select_date(date.beginning_of_month) { |day| day.cwday == 1 }
  end

  def get_friday_of_week(date)
    select_date(date) { |day| day.cwday == 5 }
  end

  def get_first_weekday_of_month(date)
    select_date(date.beginning_of_month) { |day| day.cwday <= 5 }
  end

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

  def define_issue_for_punch(punch, shift, moment)
    error = (punch.punch_time_error(shift, moment) * 60).round
    if punch.entrance then
      wording = if error < 0 then "atrasado" else "adiantado" end
      return "Funcionário chegou #{readable_duration(error.abs)} #{wording}."
    else
      wording = if error < 0 then "mais cedo" else "mais tarde" end
      return "Funcionário foi embora #{readable_duration(error.abs)} #{wording}."
    end
  end

  def define_issue_for_hours(user, hours)
    error = (user.hours_error(hours) * 60).round
    if error < 0 then
      return "Faltaram #{readable_duration(error.abs)} para o funcionário no dia."
    else
      return "Funcionário fez #{readable_duration(error.abs)} de hora extra."
    end
  end

  def readable_duration(minutes)
    h = minutes / 60
    m = minutes % 60
    if h > 0 then h.to_s + "h:" else "" end + (minutes % 60).to_s + "m"
  end


  def summary_for(user, raw_weeks, month_date)
    count = 0
    weeks = raw_weeks.map do |week|
      count += 1
      size = week_size(week)
      name = if size == 1 then
        I18n.l week.begin, format: :abbr
      else
        [week.begin, week.end].map do |w| I18n.l w, format: :abbr end.join(" a ")
      end
      Week.new(name, user.hours_worked(week), user.daily_goal, size)
    end

    days = []
    raw_weeks.each do |week|
      week.each do |day|
        issues = []
        day_range = range_for_day day
        hours = user.hours_worked day_range
        punches_for_day = user.punches.where(punched_at: day_range)
        if punches_for_day.blank? then
          issues << "Funcionário faltou."
        else
          if not user.is_hours_ok hours then
            issues << define_issue_for_hours(user, hours)
          end

          if punches_for_day.size.odd? then
            issues << "Batidas faltantes."
          end

          punches_for_day.each do |punch|
            unless punch.is_punch_time_ok nil, nil then
              issues << define_issue_for_punch(punch, nil, nil) # TODO: take out the nil
            end
          end
        end
        processed_issues = if issues.empty? then "Nenhuma." else issues.join(" ") end
        days << Day.new(day, hours, punches_for_day.to_a, processed_issues)
      end
    end

    chart = {
      categories: weeks.map { |week| week.name },
      weeks: [
        {
          name: "Decorrido",
          data: weeks.map { |week| week.hours }
        },
        {
          name: "Ideal",
          data: weeks.map { |week| week.weekly_goal }
        }]
    }

    return Summary.new(user, month_date, weeks, days, chart)
  end

end
