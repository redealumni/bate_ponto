class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user, :user_signed_in?, :user_signed_out?

  after_filter :log_cookies, if: ->{ Rails.env.development? }

  def log_cookies
    # Rails.logger.info "Session: #{session.inspect}\n"
    # Rails.logger.info "Cookies: #{cookies.signed[:login_user_id].inspect}\n"
  end

  protected

  def current_user
    @current_user ||= User.where(id: session[:user_id]).first

    if cookies.signed[:login_user_id].present?
      @current_user ||= User.where(JSON.parse(cookies.signed[:login_user_id])).first
    end

    if @current_user.present?
      session[:user_id] = @current_user.id
      cookies.permanent.signed[:login_user_id] = { id: @current_user.id, password_digest: @current_user.password_digest }.to_json
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
    redirect_to root_path, notice: "Não autorizado." unless user_signed_in?
  end

  def require_admin
    unless user_signed_in? && current_user.admin?
      redirect_to root_path, notice: "Não autorizado."
    end
  end

end
