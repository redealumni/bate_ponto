class StatsController < ApplicationController
  include DatetimeHelper

  before_filter :require_user, only: [:index]

  COLORS = %w(8DD3C7 FFFFB3 BEBADA FB8072 80B1D3 FDB462 B3DE69 FCCDE5 D9D9D9 BC80BD CCEBC5 FFED6F)

  def index
    params.permit!

    month_names = I18n.t 'date.abbr_month_names'

    @user_id = params[:user_id]
    date = params[:date]
    actual_month = params[:actual_month]

    # Do we really need to check stuff from 2 years ago by default?
    # Let the user decide instead
    default_start = 3.months.ago

    user = User.find_by_id(@user_id)
    users = if user then [user] else User.visible.by_name end

    if actual_month.nil?
      @start = if date.nil? then default_start else parse_time(date) end
    else
      @start = Date.today.at_beginning_of_month
    end

    finish = Time.zone.now
    number_of_weeks = ((finish.to_date - @start.to_date).to_i / 7).ceil

    week_ranges = get_weeks_of_range number_of_weeks.weeks.ago.to_date..finish.to_date

    @week_names = week_ranges.map do |week_range|
      I18n.l week_range.end, format: :long_abbr
    end

    @series = users.map do |u|
      hours = week_ranges.map do |week_range|
        u.time_worked(to_time_range(week_range)).to_f / 1.hour
      end
      {name: u.name, data: hours}
    end

    @pie_series = @series.map do |s|
      {y: s[:data].sum, name: s[:name]}
    end

    @user_list = [["Todos", nil]]
    @user_list.concat User.visible.by_name.pluck(:name, :id)

  end

  def gecko_daily_avg_30_days
    users = User.visible.by_name

    count = -1
    data = users.map do |u|
      count += 1
      days_worked = 0
      total_time = 0
      (1..30).each do |n|
        day = n.days.ago
        start = day.beginning_of_day
        finish = day.end_of_day
        time = u.time_worked(start..finish)
        if time > 2.hours #only days with more than 2 hours worked count
          days_worked += 1
          total_time += time
        end
      end
      avg = total_time > 0 ? (total_time.to_f / days_worked) / 1.hour : 0
      {value: avg, label: "#{u.name} (#{"%2.1f" % avg}h)", colour: COLORS[count]}
    end

    render text: {item: data}.to_json
  end

    def gecko_this_week_pie
    users = User.visible.by_name
    start = Time.zone.now.at_beginning_of_week
    finish = Time.zone.now

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_last_week_pie
    users = User.visible.by_name
    start = 1.week.ago.at_beginning_of_week
    finish = Time.zone.now.at_beginning_of_week

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_this_month_pie
    users = User.visible.by_name
    start = 1.month.ago
    finish = Time.zone.now

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_last_month_pie
    users = User.visible.by_name
    start = 1.month.ago.at_beginning_of_month
    finish = Time.zone.now.at_beginning_of_month

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_from_checkpoint_pie
    users = User.visible.by_name
    start = Time.parse('2011-11-14')
    finish = Time.zone.now

    render text: pie_data(users, start, finish).to_json
  end

  def gecko_latest_punches
    @punches = User.visible.by_name.map{ |u| u.punches.latest.first }.compact
  end

  def reports_punch
    begin_split = params[:start_date].split("\/")
    begin_date  = Time.zone.local(begin_split[2],begin_split[1],begin_split[0])

    end_split   = params[:end_date].split("\/")
    end_date    = Time.zone.local(end_split[2],end_split[1],end_split[0])

    punches     = Punch.where(created_at: begin_date .. end_date)

    data = punches.collect do |punche|
      {
        criado_em: punche.created_at.strftime("%d/%m/%y %I:%M%p"),
        status: punche.entrance? ? "Entrada" : "Saida",
        nome: punche.user.name
      }
    end
    render json: data.to_json
  end

  protected

  def pie_data(users, start, finish)
    count = -1
    data = users.map do |u|
      count += 1
      value = u.time_worked(start..finish).round
      {value: value.to_f / 1.hours, label: "#{u.name} (#{value}h)", colour: COLORS[count]}
    end
    return_data = {item: data}
  end

  def parse_time(fields)
    Date.civil(fields[:year].to_i, fields[:month].to_i, fields[:day].to_i).beginning_of_day
  end

end
