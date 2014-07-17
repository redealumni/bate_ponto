class UsersController < ApplicationController

  include DatetimeHelper

  before_filter :require_admin, except: [:edit, :update]

  # GET /users
  # GET /users.json
  def index
    @user_list = [User.visible, User.hidden]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @user_list }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(show_params[:id])
    @punches = @user.punches.latest.paginate(page: show_params[:page], per_page: 10)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new
    @user.shifts = Shifts.new_default
    @user.goals = [8] * 5

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    if create_params[:shifts].present?
      create_params[:shifts] = Shifts.from_hash JSON.parse(create_params[:shifts])
    end

    if create_params[:goals].present?
      create_params[:goals] = JSON.parse(create_params[:goals])
    end

    @user = User.new(create_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'Usuário criado.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])

    if update_params[:shifts].present?
      update_params[:shifts] = Shifts.from_hash(JSON.parse(update_params[:shifts]))
    end

    if update_params[:goals].present?
      update_params[:goals] = JSON.parse(update_params[:goals])
    end

    respond_to do |format|
      if @user.update_attributes(update_params)
        format.html do
          flash[:notice] = 'Usuário alterado com sucesso.'
          if current_user == @user
             redirect_to root_path
          else
            redirect_to @user
          end
        end
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1/hide
  # PUT /users/1/hide.json
  def hide
    @user = User.find(params[:id])

    respond_to do |format|
      @user.hidden = !@user.hidden
      @user.save
      unless @user.changed?
        # TODO better status wording
        status = if @user.hidden then "escondido" else "re-exibido" end
        format.html do
          flash[:notice] = "Usuário #{status} com sucesso."
          redirect_to users_url
        end
        format.json { head :ok }
      else
        format.html { redirect_to users_url }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url, notice: 'Usuário removido.' }
      format.json { head :ok }
    end
  end

  # GET /users/1/report
  # GET /users/1/report.pdf
  def report
    date = report_params[:partial] == "true" ? Date.today : Date.today.prev_month

    @summary = Summary.summary_for(User.find(report_params[:id]),
      get_weeks_of_month(date),
      date,
      report_params[:partial])
    @partial = report_params[:partial] == "true"
    @observations = report_params[:observations] == "true"

    respond_to do |format|
      format.html { render }
      format.pdf do
        @format = :pdf
        render pdf: "relatorio_#{@summary.user.name}.pdf",
          template: "users/report.html.erb",
          layout: "report_pdf"
      end
    end
  end

  private
    # Safe parameters for show
    def show_params
      params.require(:id)
      params.permit(:id, :page)
    end

    # Safe parameters for report
    def report_params
      params.permit(:id, :partial, :observations)
    end

    # Safe parameters for admin reports
    def admin_reports_params
      params.permit(:partial)
    end

    # Safe parameters for user creation / updating
    def user_params
      if current_user.admin?
        params.require(:user).permit(:name, :password, :token, :hidden, :admin, :flexible_goal, :goals, :shifts)
      else
        params.require(:user).permit(:password)
      end
    end

    alias_method :create_params, :user_params
    alias_method :update_params, :user_params
end
