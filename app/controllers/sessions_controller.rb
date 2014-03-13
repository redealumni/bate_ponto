class SessionsController < ApplicationController
  before_filter :require_user, only: [:delete]

  def new
    @user = User.new
  end

  def create
    permit_params!
    
    @user = User.find_by_name(params[:user][:name])
    if @user.try(:authenticate, params[:user][:password])
      session[:user_id] = @user.id
      cookies.permanent.signed[:login_user_id] = { id: @user.id, password_digest: @user.password_digest }.to_json
      redirect_to root_path, notice: "Logado com sucesso!" # Or whatever you want i.e. redirect_to user
    else
      render :new, flash: { error: "bad email/password combination" }
    end
  end

  def destroy
    session.delete(:user_id)
    cookies.delete(:login_user_id)
    redirect_to root_path, notice: "Você fez logout!"
  end

  private
    # Rails 4: strong parameters functionality by default. For now just make it work and permit everything:
    def permit_params!
      params.permit!
    end
end