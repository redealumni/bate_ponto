# encoding: utf-8
class SessionsController < ApplicationController
  before_filter :require_user, :only => [:delete]
 
  def new
    @user = User.new
  end
 
  def create
    @user = User.find_by_name(params[:user][:name])
    if @user.try(:authenticate, params[:user][:password])
      session[:user_id] = @user.id
      cookies.permanent.signed[:login_user_id] = @user.id, @user.password_digest
      redirect_to root_path, :notice => "Logado com sucesso!" # Or whatever you want i.e. redirect_to user
    else
      render :new, :flash => { :error => "bad email/password combination" }
    end
  end
 
  def destroy
    session.delete(:user_id)
    cookies.delete(:login_user_id)
    redirect_to root_path, :notice => "Você fez logout!"
  end
end