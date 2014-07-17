require 'test_helper'

class UserTest < ActiveSupport::TestCase

  include DatetimeHelper

  def setup
    @user = User.create(name: "Joao Cohones", password: "abc123")
  end

  def yesterday_range
    day = Date.yesterday
    day.beginning_of_day..day.end_of_day
  end

  def yesterday_time(time)
    Date.yesterday.beginning_of_day + time
  end

  private :yesterday_time, :yesterday_range

  test "time_worked caso normal" do
    @punches = @user.punches.create(punched_at: (yesterday_time(1.hour)))
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(15.hours)))

    assert_equal 9.hours, @user.time_worked(yesterday_range)
  end

  test "time_worked punches falta fim" do
    @punches = @user.punches.create(punched_at: (yesterday_time(1.hour)))
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours)))

    assert_equal 18.hours, @user.time_worked(yesterday_range).ceil
  end

  test "time_worked punches falta início" do
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(17.hours)))

    assert_equal 12.hours, @user.time_worked(yesterday_range).ceil
  end


  test "time_worked ignora entrada faltante no meio" do
    @punches = @user.punches.create(punched_at: (yesterday_time(1.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(15.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(20.hours)))
    @punches.update_attribute(:punched_at, (yesterday_time(3.hours)))

    assert_equal 7.hours, @user.time_worked(yesterday_range).ceil
  end

  test "time_worked ignora saída faltante no meio" do
    @punches = @user.punches.create(punched_at: (yesterday_time(1.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(15.hours)))
    @punches = @user.punches.create(punched_at: (yesterday_time(20.hours)))
    @punches.update_attribute(:punched_at, (yesterday_time(8.hours)))
    
    assert_equal 11.hours, @user.time_worked(yesterday_range).ceil
  end

  test "time_worked semana inteira" do
    start = get_monday_of_week(1.week.ago.to_date)
    finish = (start + 4.days).to_date

    (start..finish).each do |day|
      [1, 5, 10, 14].each { |h| @user.punches.create(punched_at: day + h.hours) }
    end

    assert_equal 40.hours, @user.time_worked(start.midnight..finish.end_of_day).ceil
  end

end
