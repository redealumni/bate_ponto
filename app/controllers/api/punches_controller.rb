module Api
  class PunchesController < ActionController::Base
    before_action :restrict_access, only: [:index,:create]

    respond_to :html, :json

    def index
      respond_with @user.punches.latest.first(10)
    end

    def create
      last_punch = @user.punches.latest.first
      if last_punch.present? && last_punch.created_at > 5.minutes.ago
        #remove punches sequenciais (para correção rápida)
        removed_punch = last_punch.destroy
        response = { entrance: 'destroyed'}
        render json: response
      else
        @punch = @user.punches.new(create_params)

        if @punch.save
          render json: @punch
        else
          render json: @punch.errors, status: :unprocessable_entity
        end
      end
    end

    def mobile_punch
      @user = User.find_by_name(session_params[:name])
      if @user.try(:authenticate, session_params[:password])
        create_punch
      else
        render json: {info: "Falha na authenticação! Verifique nome e senha"}.to_json
      end
    end

    def list_mobile
      @user = User.find_by_name(session_params[:name])
      if @user.try(:authenticate, session_params[:password])
        respond_to do |format|
          format.json { render json: @user.punches.latest.first(10) }
        end
      else
        render json: {info: "Falha na authenticação! Verifique nome e senha"}.to_json
      end
    end

    def login
      @user = User.find_by_name(session_params[:name])
      if @user.try(:authenticate, session_params[:password])
        render json: {info: "success" }.to_json
      else
        render json: {info: "error" }.to_json
      end
    end


    protected

    def restrict_access
      @user = User.find_by(token: params[:user_token]) || User.find_by(slack_username: params[:punch][:user][:slack])
      if API_TOKEN.blank? || @user.blank? || params[:api_token] != API_TOKEN
        head :unauthorized
      end
    end

    # Get params for creating
    def create_params
      params.require(:punch).permit(:comment,:user)
    end

    def session_params
      params.require(:user).permit(:name, :password)
    end

    def create_punch
      last_punch = @user.punches.latest.first
      if last_punch.present? && last_punch.created_at > 5.minutes.ago
        #remove punches sequenciais (para correção rápida)
        last_punch.destroy
        response = { punch: @user.punches.latest.first, punch_status: 'destroyed'}
        render json: response
      else
        @punch = @user.punches.new(create_params)

        if @punch.save
          response = { punch: @punch, punch_status: 'punched'}
          render json: response
        else
          render json: @punch.errors, status: :unprocessable_entity
        end
      end
    end
  end
end
