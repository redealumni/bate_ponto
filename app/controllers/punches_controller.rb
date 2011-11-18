# encoding: utf-8
class PunchesController < ApplicationController
  
  before_filter :require_user, :except => [:index, :create]
  
  # GET /punches
  # GET /punches.json
  def index
    @punches = user_signed_in? ? current_user.punches.latest.first(10) : []
    @punch = user_signed_in? ? current_user.punches.new : Punch.new
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @punches }
    end
  end

  # POST /punches
  # POST /punches.json
  def create
    user_params = params[:punch].delete(:user)
    @punches = user_signed_in? ? current_user.punches.latest : []
    @punch = user_signed_in? ? current_user.punches.new(params[:punch]) : Punch.new

    if user_params
      if user = User.find_by_name(user_params[:name]).try(:authenticate, user_params[:password])
        @current_user = user
        session[:user_id] = cookies.permanent.signed[:login_user_id] = user.id
        @punches = current_user.punches.latest
        @punch = current_user.punches.new(params[:punch])
      else
        render :index, :flash => { :error => "Senha inválida." } and return
      end
    end
    
    unless user_signed_in?
      render :index, :flash => { :error => "Precisa se logar!" } and return
    end

    respond_to do |format|
      if @punch.save
        format.html { redirect_to root_path, :notice => 'Cartão batido com sucesso!' }
        format.json { render :json => @punch, :status => :created, :location => @punch }
      else
        format.html { render :action => "index" }
        format.json { render :json => @punch.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /punches/1
  # PUT /punches/1.json
  def update
    @punch = current_user.punches.find(params[:id])

    respond_to do |format|
      if @punch.update_attributes(params[:punch])
        format.html { redirect_to root_path, :notice => 'Batida de ponto alterada.' }
        format.json { head :ok }
      else
        format.html { render :action => "index" }
        format.json { render :json => @punch.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /punches/1
  # DELETE /punches/1.json
  def destroy
    @punch = current_user.punches.find(params[:id])
    @punch.destroy

    respond_to do |format|
      format.html { redirect_to punches_url }
      format.json { head :ok }
    end
  end
end
