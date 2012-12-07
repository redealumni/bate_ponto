# encoding: utf-8

require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = User.create(:name => "Joao Cohones", :password => "abc123")
  end

  test "hours_worked caso normal" do
    #entrou 1:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 1.hour))
    #saiu 5:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 5.hours))
    #entrou 10:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 10.hours))
    #saiu 15:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 15.hours))

    assert_equal 9, @user.hours_worked(Time.now.beginning_of_day..Time.now.end_of_day)
  end

  test "hours_worked punches falta fim" do
    #entrou 1:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 1.hour))
    #saiu 5:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 5.hours))
    #entrou 10:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 10.hours))

    #18 horas, até o fim do período
    assert_equal 18, @user.hours_worked(Time.now.beginning_of_day..Time.now.end_of_day)
  end

  test "hours_worked punches falta início" do
    #saiu 5:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 5.hours))
    #entrou 10:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 10.hours))
    #saiu 17:00
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 17.hours))

    #12 horas, desde o início do dia
    assert_equal 12, @user.hours_worked(Time.now.beginning_of_day..Time.now.end_of_day)
  end


  test "hours_worked ignora entrada faltante no meio" do
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 1.hours)) #entra
                                                                              # 3:00       sai
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 5.hours)) #sai
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 10.hours)) #entra
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 15.hours)) #sai

    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 20.hours))
    @punches.update_attribute(:punched_at, (Time.now.beginning_of_day + 3.hours) ) #  sai lá atrás

    assert_equal 7, @user.hours_worked(Time.now.beginning_of_day..Time.now.end_of_day)
  end

  test "hours_worked ignora saída faltante no meio" do
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 1.hours)) #entra
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 5.hours)) #sai
                                                                              # 8         entra
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 10.hours))#entra
    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 15.hours))#sai

    @punches = @user.punches.create(:punched_at => (Time.now.beginning_of_day + 20.hours))#some
    @punches.update_attribute(:punched_at, (Time.now.beginning_of_day + 8.hours) ) # entra lá atrás
    
    assert_equal 11, @user.hours_worked(Time.now.beginning_of_day..Time.now.end_of_day)
  end

end
