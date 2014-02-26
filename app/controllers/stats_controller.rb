class StatsController < ApplicationController

  COLORS = %w(8DD3C7 FFFFB3 BEBADA FB8072 80B1D3 FDB462 B3DE69 FCCDE5 D9D9D9 BC80BD CCEBC5 FFED6F)

  def index
    month_names = %w(JAN FEV MAR ABR MAI JUN JUL AGO SET OUT NOV DEZ)

    @users = User.visible.by_name
    start = Time.parse('2012-10-01')
    finish = Time.now
    number_of_weeks = ((finish - start) / 60 / 60 / 24 / 7).ceil

    @week_ranges = []
    last_week = start
    (1..number_of_weeks).each do
      @week_ranges.push last_week..(1.week.since(last_week))
      last_week += 1.week
    end

    @week_names = @week_ranges.map do |week_range|
      #o ano em que o primeiro dia da semana começa
      year = week_range.begin.at_beginning_of_week.year - 2000
      #o mês em que o primeiro dia da semana começa
      month = week_range.begin.at_beginning_of_week.month
      #o número da semana dentro do mês
      week_number = ((week_range.begin.at_beginning_of_week - week_range.begin.at_beginning_of_month) / 60 / 60 / 24 / 7).ceil
      "%1d%3s%2.2d" % [week_number, month_names[month-1], year]
    end

    @series = @users.map do |u|
      hours = @week_ranges.map do |week_range|
        u.hours_worked(week_range).round
      end
      {name: u.name, data: hours}
    end

    @pie_series = @users.map do |u|
      {y: u.hours_worked(start..finish).round, name: u.name}
    end

  end

  def gecko_daily_avg_30_days
    users = User.visible.by_name

    count = -1
    data = users.map do |u|
      count += 1
      days_worked = 0
      total_hours = 0
      (1..30).each do |n|
        day = n.days.ago
        start = day.beginning_of_day
        finish = day.end_of_day
        hours = u.hours_worked(start..finish)
        if hours > 2 #only days with more than 2 hours worked count
          days_worked += 1
          total_hours += hours
        end
      end
      avg = total_hours > 0 ? total_hours.to_f/days_worked : 0
      {value: avg, label: "#{u.name} (#{"%2.1f" % avg}h)", colour: COLORS[count]}
    end

    render text: {item: data}.to_json
  end

    def gecko_this_week_pie
    users = User.visible.by_name
    start = Time.now.at_beginning_of_week
    finish = Time.now

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_last_week_pie
    users = User.visible.by_name
    start = 1.week.ago.at_beginning_of_week
    finish = Time.now.at_beginning_of_week

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_this_month_pie
    users = User.visible.by_name
    start = 1.month.ago
    finish = Time.now

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_last_month_pie
    users = User.visible.by_name
    start = 1.month.ago.at_beginning_of_month
    finish = Time.now.at_beginning_of_month

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_from_checkpoint_pie
    users = User.visible.by_name
    start = Time.parse('2011-11-14')
    finish = Time.now

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_latest_punches
    @punches = User.visible.by_name.map{|u| u.punches.latest.first}.compact
  end

  protected

  def pie_data(users, start, finish)
    count = -1
    data = users.map do |u|
      count += 1
      value = u.hours_worked(start..finish).round
      {value: value, label: "#{u.name} (#{value}h)", colour: COLORS[count]}
    end
    return_data = {item: data}
  end

end
