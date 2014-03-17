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

      goal = user.weekly_goal week.begin.cwday - 1, week.end.cwday - 1
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
        hours = hours_worked_less_lunch user, day_range, weekday
        punches_for_day = user.punches.where(punched_at: day_range)
        if punches_for_day.blank? then
          issues << "Funcionário faltou."
        else
          if not user.is_hours_ok weekday, hours then
            issues << define_issue_for_hours(user, weekday, hours)
          end

          if punches_for_day.size < user.shifts.num_of_shifts(weekday) * 2 then
            issues << "Batidas faltantes."
          end

          moment = :entrance

          punches_for_day.each.with_index do |punch, idx|
            shift = (idx / 2) + 1
            break if shift > user.shifts.num_of_shifts(weekday)

            unless punch.is_punch_time_ok weekday, shift, moment then
              issues << define_issue_for_punch(punch, weekday, shift, moment)
            end
            moment = swap(moment, :entrance, :exit)
          end
        end

        processed_issues = if issues.empty? then
          "Nenhuma."
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
  
  def self.define_issue_for_punch(punch, day, shift, moment)
    error = punch.punch_time_error day, shift, moment
    if punch.entrance
      wording = if error < 0 then
        "atrasado"
      else
        "adiantado"
      end
      "Funcionário chegou #{readable_duration(error.abs)} #{wording}."
    else
      wording = if error < 0 then
        "mais cedo"
      else
        "mais tarde"
      end
      "Funcionário foi embora #{readable_duration(error.abs)} #{wording}."
    end
  end

  def self.define_issue_for_hours(user, weekday, hours)
    error = (user.hours_error(weekday, hours) * 60).ceil
    if error < 0
      "Faltaram #{readable_duration(error.abs)} para o funcionário no dia."
    else
      "Funcionário fez #{readable_duration(error.abs)} de hora extra."
    end
  end

  def self.hours_worked_less_lunch(user, date_range)
    lunch_time = date_range.map { |date| date.cwday }.map { |weekday| 
      user.shifts.lunch_time(Shifts::NUM_MAPPING[weekday]) 
    }.sum.to_f / 60

    user.hours_worked(date_range) - lunch_time
  end

  def self.swap(value, first, second)
    if value == first then second else first end
  end

end
