# Summary classes used for representing user reports

Week = Struct.new(:name, :hours, :daily_goal, :week_size) do

  def problem?
    (weekly_goal - hours).abs < User::TOLERANCE_HOURS * week_size
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

Summary = Struct.new(:user, :date, :weeks, :days, :chart) do
  extend DatetimeHelper

  def self.summary_for(user, raw_weeks, month_date)
    weeks = raw_weeks.map do |week|
      size = date_range_size(week)
      name = if size == 1 then
        I18n.l week.begin, format: :abbr
      else
        partial = [week.begin, week.end].map { |w| I18n.l w, format: :abbr }
        partial.join(' a ')
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

          if punches_for_day.size < user.num_of_shifts * 2 then
            issues << "Batidas faltantes."
          end

          count = 0
          moment = :entrance
          punches_for_day.each do |punch|
            shift = 1 + (count / 2)
            unless punch.is_punch_time_ok shift, moment then
              issues << define_issue_for_punch(punch, shift, moment)
            end
            moment = swap(moment, :entrance, :exit)
            count += 1
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
  
  def self.define_issue_for_punch(punch, shift, moment)
    error = punch.punch_time_error shift, moment
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

  def self.define_issue_for_hours(user, hours)
    error = (user.hours_error(hours) * 60).ceil
    if error < 0
      "Faltaram #{readable_duration(error.abs)} para o funcionário no dia."
    else
      "Funcionário fez #{readable_duration(error.abs)} de hora extra."
    end
  end

  def self.swap(value, first, second)
    if value == first then second else first end
  end

end
