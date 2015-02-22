module Api
  class PunchesController < ActionController::Base
    before_action :restrict_access

    respond_to :html, :json

    def index
      respond_with @user.punches.latest.first(10)
    end

    def create
      last_punch = @user.punches.latest.first
      binding.pry
      if last_punch.present? && last_punch.created_at > 5.minutes.ago
        #remove punches sequenciais (para correção rápida)
        removed_punch = last_punch.destroy
        respond_with removed_punch, status: :ok
      else
        @punch = @user.punches.new(create_params)

        if @punch.save
          render json: @punch
        else
          render json: @punch.errors, status: :unprocessable_entity
        end
      end
    end

    protected

    def restrict_access
      @user = User.find_by(token: params[:user_token]) || User.find_by(slack_username: params[:punch][:user][:slack])
      binding.pry
      if API_TOKEN.blank? || @user.blank? || params[:api_token] != API_TOKEN
        head :unauthorized
      end
    end

    # Get params for creating
    def create_params
      params.require(:punch).permit(:comment,:user)
    end

    def user_params
      params.require(:punch).permit(user: [:name, :password, :token])[:user]
    end
  end
end
