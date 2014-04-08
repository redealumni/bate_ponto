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
    @user = User.find(id_param)
  end

  # POST /users
  # POST /users.json
  def create
    create_params = user_params

    create_params[:shifts] = Shifts.from_hash JSON.parse(create_params[:shifts])
    create_params[:goals] = JSON.parse(create_params[:goals])

    @user = User.new(create_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
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
    update_params = user_params

    update_params[:shifts] = Shifts.from_hash JSON.parse(update_params[:shifts]) if current_user.admin?
    update_params[:goals] = JSON.parse(update_params[:goals]) if current_user.admin?


    @user = User.find(id_param)

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
    @user = User.find(id_param)

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
    @user = User.find(id_param)
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
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

  # GET /admin/absences
  def absences
    date = admin_reports_params[:partial] == "true" ? Date.today : Date.today.prev_month
    
    @absences = Summary.absences_for date
    @partial = admin_reports_params[:partial] == "true"

    respond_to do |format|
      format.html { render }
    end
  end

  # GET /admin/reports
  def report_all
    partial = admin_reports_params[:partial] == "true"
    date = partial ? Date.today : Date.today.prev_month

    temp_file = Tempfile.new("reports-#{request.uuid}")
    date_range = get_weeks_of_month(date)

    begin
      file_name = "relatorios_#{Date.today.to_s(:filename)}.zip"
      @format = :pdf

      Zip::OutputStream.open temp_file.path do |z|
        User.visible.find_each do |u|
          @summary = Summary.summary_for u, date_range, date, partial
          
          pdf_string = render_to_string formats: [:html],
            template: "users/report.html.erb", 
            layout: "report_pdf"

          pdf_data = WickedPdf.new.pdf_from_string(pdf_string)

          z.put_next_entry "relatorio_#{@summary.user.name}.pdf"
          z.write pdf_data
        end
      end

      send_file temp_file.path, type: 'application/zip', filename: file_name
    ensure 
      temp_file.close
    end
  end

  private
    # Safe parameters for show
    def show_params
      params.require(:id)
      params.permit(:id, :page)
    end

    # Safe id param
    def id_param
      params.require(:id)
    end

    # Safe parameters for report
    def report_params
      params.permit(:id, :partial)
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

end
