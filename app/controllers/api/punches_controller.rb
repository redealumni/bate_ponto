module Api
  class PunchesController < ActionController::Base
    before_action :restrict_access

    respond_to :json

    def index
      respond_with @user.punches
    end

    protected

    def restrict_access
      @user = User.find_by(token: params[:user_token])

      if @user.blank? || params[:api_token] != API_TOKEN
        head :unauthorized
      end
    end
  end
end
