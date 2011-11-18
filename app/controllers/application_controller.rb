# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user, :user_signed_in?, :user_signed_out?

  protected
  
    def current_user
      if @current_user ||= User.find_by_id(session[:user_id]) || User.find_by_id_and_password_digest(*cookies.signed[:login_user_id])
        session[:user_id] = @current_user.id
        cookies.permanent.signed[:login_user_id] = [@current_user.id, @current_user.password_digest]
      else
        session.delete(:user_id)
        cookies.delete(:login_user_id)
      end
      @current_user
    end

    def user_signed_in?
      !!current_user
    end

    def user_signed_out?
      !user_signed_in?
    end
    
    def require_user
      redirect_to root_path, :notice => "Não autorizado." unless user_signed_in?
    end
    
    def require_admin
      unless user_signed_in? && current_user.admin?
        redirect_to root_path, :notice => "Não autorizado."
      end
    end
end
