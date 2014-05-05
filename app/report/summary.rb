# Summary classes used for representing user reports

Week = Struct.new(:name, :hours, :weekly_goal, :week_size) do
  def problem?
    (weekly_goal - hours).abs < User::TOLERANCE_HOURS * week_size
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


Summary = Struct.new(:user, :date, :weeks, :days, :chart) do
  extend DatetimeHelper

  def self.absences_for(month_date)
    days = get_days_for_ranges get_weeks_of_month(month_date)
    
    results = {
      days: days,
      registers: Hash.new { |hash, key| hash[key] = [] }
    }

    User.all.find_each do |user|
      days.each do |day|
        punches_for_day = user.punches.where(punched_at: range_for_day(day))
        results[:registers][user] << punches_for_day.blank?
      end
    end

    return results
  end

  def self.summary_for(user, raw_weeks, month_date, partial = false)
    weeks = raw_weeks.map do |week|
      # If partial mode enabled, don't bother with future dates
      week = ignore_future(week) if partial
      next if partial and week.nil?

      size = date_range_size(week)

      name = if size == 1 then
        I18n.l week.begin, format: :abbr
      else
        [week.begin, week.end].map { |w| I18n.l w, format: :abbr }.join(' a ')
      end

      goal = user.weekly_goal (week.begin.cwday - 1)..(week.end.cwday - 1)
      Week.new(name, hours_worked_less_lunch(user, week), goal, size)
    end.compact

    days = []
    raw_weeks.each do |week|
      week.each do |day|
        # If partial mode enabled, don't bother with future dates
        break if partial and day > Date.today

        weekday = Shifts::NUM_MAPPING[day.cwday]

        issues = []
        day_range = range_for_day day
        hours = hours_worked_less_lunch_in_day user, day
        punches_for_day = user.punches.where(punched_at: day_range)
        if punches_for_day.blank? then
          issues << "Funcionário faltou."
        else
          if not user.is_hours_ok weekday, hours then
            issues << define_issue_for_hours(user, weekday, hours)
          end
        end

        readable_hours = if hours == 0 then "" else readable_duration(hours, format: :hours) + " feitos no dia. " end

        processed_issues = readable_hours + if issues.empty? then
          "Nenhuma irregularidade."
        else 
          issues.join(" ")
        end

        days << Day.new(day, hours, punches_for_day.to_a, processed_issues)
      end
    end

    chart = 
    {
      categories: weeks.map { |week| week.name },
      weeks: [
        {
          name: "Decorrido",
          data: weeks.map { |week| week.hours.round }
        },
        {
          name: "Ideal",
          data: weeks.map { |week| week.weekly_goal.round }  
        }
      ]
    }

    return Summary.new(user, month_date, weeks, days, chart)
  end

  # Helper private methods
  private
  
  def self.define_issue_for_hours(user, weekday, hours)
    error = (user.hours_error(weekday, hours) * 60).ceil
    if error < 0
      "Faltaram #{readable_duration(error.abs)} para o funcionário no dia."
    else
      "Funcionário fez #{readable_duration(error.abs)} de hora extra."
    end
  end

  def self.check_range(date_range)
    date_range.begin.to_date == date_range.end.to_date
  end

  def self.hours_worked_less_lunch(user, date_range)
    weekdays = date_range.to_a.map { |date| date.cwday }

    lunch_time = weekdays.map { |weekday| 
      user.shifts.lunch_time(Shifts::NUM_MAPPING[weekday]) 
    }.sum.to_f / 60

    user.hours_worked(to_time_range(date_range)) - lunch_time
  end

  def self.hours_worked_less_lunch_in_day(user, day)
    user.hours_worked(range_for_day(day)) - user.shifts.lunch_time(Shifts::NUM_MAPPING[day.cwday]).to_f/60
  end

  def self.swap(value, first, second)
    if value == first then second else first end
  end

end
