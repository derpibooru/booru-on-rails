# frozen_string_literal: true

class Admin::UserWhitelistsController < ApplicationController
  before_action :check_auth
  before_action :load_whitelist, only: [:edit, :update, :destroy]

  def index
    @title = 'User Whitelists'
    @user_whitelists = if params[:q]
      UserWhitelist.where(user_id: User.where('name ILIKE ?', params[:q] + '%').select(:id))
    else
      UserWhitelist
    end.order(created_at: :desc).includes(:user).page(params[:page]).per(50)

    respond_to do |format|
      format.html
      format.json { render json: @user_whitelists }
    end
  end

  def new
    @title = 'New User Whitelist'
    @user_whitelist = UserWhitelist.new
    @username = params[:username]
  end

  def create
    @user_whitelist = UserWhitelist.new(whitelist_params)
    respond_to do |format|
      if @user_whitelist.save
        format.html { redirect_to admin_user_whitelists_path, notice: 'User was added to whitelist.' }
        format.json { render json: @user_whitelist, status: :created, location: admin_user_whitelists_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @user_whitelist.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @title = "Editing Whitelist Entry for #{@user_whitelist.username}"
  end

  def update
    respond_to do |format|
      if @user_whitelist.update(params.require(whitelist_params))
        format.html { redirect_to admin_user_whitelists_path, notice: 'User whitelist entry updated.' }
        format.json { render json: @user_whitelist, status: :created, location: admin_user_whitelists_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @user_whitelist.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user_whitelist.destroy
    respond_to do |format|
      format.html { redirect_to admin_user_whitelists_path }
      format.json { head :ok }
    end
  end

  private

  def check_auth
    authorize! :manage, UserWhitelist
  end

  def load_whitelist
    @user_whitelist = UserWhitelist.includes(:user).find_by(id: params[:id])
  end

  def whitelist_params
    params.require(:user_whitelist).permit(:username, :reason)
  end
end
