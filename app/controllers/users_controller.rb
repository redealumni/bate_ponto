# encoding: utf-8
class UsersController < ApplicationController

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

  # PUT /users/hide/1
  # PUT /users/hide/1.json
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

  private
    # Rails 4: strong parameters functionality by default. For now just make it work and permit everything:
    def permit_params!
      params.permit!
    end
end
