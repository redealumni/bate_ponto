class PunchesController < ApplicationController

  before_filter :require_admin, only: [:update, :destroy]

  # GET /punches
  # GET /punches.json
  def index
    @punches = user_signed_in? ? current_user.punches.latest.first(10) : []
    @punch = user_signed_in? ? current_user.punches.new : Punch.new

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @punches }
    end
  end

  def token
    @punch = Punch.new
    @punches = Punch.latest.where("punched_at > ?", 1.day.ago.beginning_of_day )
  end

  # POST /punches
  # POST /punches.json
  def create
    @punches = user_signed_in? ? current_user.punches.latest : []
    @punch = user_signed_in? ? current_user.punches.new(create_params) : Punch.new

    if user_params  #bate como outro usuário ou por token
      if user = User.find_by_name(user_params[:name]).try(:authenticate, user_params[:password]) || User.find_by_token(user_params[:token])
        @punch = user.punches.new(create_params)
      else
        respond_to do |format|
          format.html { redirect_to root_path, notice: "Senha ou token inválidos." and return }
          format.js   { render json: { notice: "Senha ou token inválidos." }, status: :unprocessable_entity and return }
          format.json { render json: { notice: "Senha ou token inválidos." }, status: :unprocessable_entity and return }
        end
      end
    end

    respond_to do |format|
      # horrible "rescue nil"
      # avoids problems when @punch doesn't have a User
      last_punch = @punch.user.punches.latest.first rescue nil

      if last_punch && last_punch.created_at > 5.minutes.ago
        #remove punches sequenciais (para correção rápida)
        removed_punch = last_punch.destroy
        format.html { redirect_to root_path, notice: 'Sua última batida foi removida!' }
        format.js   { render json: { delete: removed_punch }, status: :ok, location: removed_punch }
        format.json { render json: { delete: removed_punch }, status: :ok, location: removed_punch }
      else
        if @punch.save
          format.html { redirect_to root_path, notice: 'Cartão batido com sucesso!' }
          format.js   {
            render json: { html: render_to_string({
                                  partial: 'punch_info',
                                  locals: { punch: @punch }
                                 }),
                           create: @punch
                          },
                    status: :created,
                    location: @punch
          }
          format.json { render json: @punch, status: :created, location: @punch }
        else
          format.html { render action: "index" }
          format.js   { render json: @punch.errors, status: :unprocessable_entity }
          format.json { render json: @punch.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /punches/1
  # PUT /punches/1.json
  def update
    @punch = Punch.find(params[:id])

    respond_to do |format|
      if @punch.update!(update_params)
        format.html { redirect_to root_path, notice: 'Batida de ponto alterada.' }
        format.js
        format.json { head :ok }
      else
        format.html { render action: "index" }
        format.js
        format.json { render json: @punch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /punches/1
  # DELETE /punches/1.json
  def destroy
    @punch = Punch.find(params[:id])

    @punch.destroy

    respond_to do |format|
      format.html { redirect_to punches_url, notice: 'Batida de ponto removida.' }
      format.js
      format.json { head :ok }
    end
  end

  private

  # Get params for creating
  def create_params
    params.require(:punch).permit(:comment)
  end

  # Get user params for unlogged punching
  def user_params
    params.require(:punch).permit(user: [:name, :password, :token])[:user]
  end

  # Get params for updating
  def update_params
    params.require(:punch).permit(:comment, :punched_at)
  end
end
