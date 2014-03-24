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

  test "hours_worked caso normal" do
    #entrou 1:00
    @punches = @user.punches.create(punched_at: (yesterday_time(1.hour)))
    #saiu 5:00
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours)))
    #entrou 10:00
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours)))
    #saiu 15:00
    @punches = @user.punches.create(punched_at: (yesterday_time(15.hours)))

    assert_equal 9, @user.hours_worked(yesterday_range).ceil
  end

  test "hours_worked punches falta fim" do
    #entrou 1:00
    @punches = @user.punches.create(punched_at: (yesterday_time(1.hour)))
    #saiu 5:00
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours)))
    #entrou 10:00
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours)))

    #18 horas, até o fim do período
    assert_equal 18, @user.hours_worked(yesterday_range).ceil
  end

  test "hours_worked punches falta início" do
    #saiu 5:00
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours)))
    #entrou 10:00
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours)))
    #saiu 17:00
    @punches = @user.punches.create(punched_at: (yesterday_time(17.hours)))

    #12 horas, desde o início do dia
    assert_equal 12, @user.hours_worked(yesterday_range).ceil
  end


  test "hours_worked ignora entrada faltante no meio" do
    @punches = @user.punches.create(punched_at: (yesterday_time(1.hours))) #entra
                                                                              # 3:00       sai
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours))) #sai
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours))) #entra
    @punches = @user.punches.create(punched_at: (yesterday_time(15.hours))) #sai

    @punches = @user.punches.create(punched_at: (yesterday_time(20.hours)))
    @punches.update_attribute(:punched_at, (yesterday_time(3.hours)) ) #  sai lá atrás

    assert_equal 7, @user.hours_worked(yesterday_range).ceil
  end

  test "hours_worked ignora saída faltante no meio" do
    @punches = @user.punches.create(punched_at: (yesterday_time(1.hours))) #entra
    @punches = @user.punches.create(punched_at: (yesterday_time(5.hours))) #sai
                                                                              # 8         entra
    @punches = @user.punches.create(punched_at: (yesterday_time(10.hours)))#entra
    @punches = @user.punches.create(punched_at: (yesterday_time(15.hours)))#sai

    @punches = @user.punches.create(punched_at: (yesterday_time(20.hours)))#some
    @punches.update_attribute(:punched_at, (yesterday_time(8.hours)) ) # entra lá atrás
    
    assert_equal 11, @user.hours_worked(yesterday_range).ceil
  end

  test "hours_worked semana inteira" do
    start = get_monday_of_week(1.week.ago.to_date)
    finish = (start + 4.days).to_date

    (start..finish).each do |day|
      [1, 5, 10, 14].each { |h| @user.punches.create(punched_at: day + h.hours) }
    end

    assert_equal 40, @user.hours_worked(start.midnight..finish.end_of_day).ceil
  end

end
