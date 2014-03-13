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
    params.permit!
    
    @user = User.find(params[:id])
    @punches = @user.punches.latest.paginate(page: params[:page], per_page: 10)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

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
    params.permit!
    params[:user][:shifts] = JSON.parse(params[:user][:shifts])

    @user = User.new(params[:user])

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
    params.permit!
    params[:user][:shifts] = JSON.parse(params[:user][:shifts])

    @user = User.find(params[:id])
    params[:user].delete(:admin) unless current_user.admin?

    respond_to do |format|
      if @user.update_attributes(params[:user])
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
    params.permit!

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
    params.permit!

    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :ok }
    end
  end

  # GET /users/1/report
  # GET /users/1/report.pdf
  def report
    params.permit!

    if params[:id] == 'all'
      report_for_all
    else
      date = Date.today.prev_month
      @summary = Summary.summary_for User.find(params[:id]), get_weeks_of_month(date), date
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
  end

  private
    def report_for_all
      temp_file = Tempfile.new("reports-#{request.uuid}")
      date = Date.today.prev_month
      date_range = get_weeks_of_month(date)

      begin
        file_name = "relatorios_#{Date.today.to_s(:filename)}.zip"
        @format = :pdf

        Zip::OutputStream.open temp_file.path do |z|
          User.visible.find_each do |u|
            @summary = Summary.summary_for u, date_range, date
            
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

    # Rails 4: strong parameters functionality by default. For now just make it work and permit everything:
    def permit_params!
      params.permit!
    end
end
