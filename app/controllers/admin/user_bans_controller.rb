# frozen_string_literal: true

class Admin::UserBansController < ApplicationController
  before_action :load_ban, only: [:show, :edit, :update, :destroy]

  def index
    @title = 'Admin - User Bans'
    authorize! :mod_read, UserBan
    @bans = if params[:q].present?
      # Search user names, ban reasons, and ban notes.
      UserBan.where('(user_id IN (?)) OR (generated_ban_id IN (?)) OR (to_tsvector(reason) @@ plainto_tsquery(?)) OR (to_tsvector(note) @@ plainto_tsquery(?))',
                    User.where('name ILIKE ?', params[:q] + '%').select(:id),
                    params[:q], params[:q], params[:q])
    elsif params[:user_id]
      User.find(params[:user_id]).bans
    else
      UserBan
    end.order(created_at: :desc).includes(:user).page(params[:page]).per(25)

    respond_to do |format|
      format.html
      format.json { render json: @bans }
    end
  end

  # TODO: Unfinished page
  def show
    @title = "Ban History: #{@ban.username}"
    authorize! :manage, UserBan
  end

  def new
    authorize! :mod_read, UserBan
    @ban = UserBan.new
    @user = if params[:username]
      User.find_by(name: params[:username])
    elsif params[:user_id]
      User.find_by(id: params[:user_id])
    end

    @title = (@user ? "Ban #{@user.name}" : 'New User Ban')
    respond_to do |format|
      format.html
      format.json { render json: @ban }
    end
  end

  def create
    @ban = UserBan.new(user_ban_params)
    @ban.banning_user = current_user
    authorize! :create, @ban
    respond_to do |format|
      if @ban.save
        modfeed_push('new')
        format.html { redirect_to admin_user_bans_path, notice: 'User was successfully banned.' }
        format.json { render json: @ban, status: :created, location: admin_user_bans_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @ban.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @title = "Editing User Ban: #{@ban.username}"
    authorize! :edit, UserBan
  end

  def update
    authorize! :edit, UserBan
    respond_to do |format|
      if @ban.update(user_ban_params)
        modfeed_push('edited')
        format.html { redirect_to admin_user_bans_path, notice: 'User ban successfully updated.' }
        format.json { render json: @ban, status: :created, location: admin_user_bans_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @ban.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, @ban
    @ban.destroy
    respond_to do |format|
      modfeed_push('destroyed')
      format.html { redirect_to admin_user_bans_path }
      format.json { head :ok }
    end
  end

  private

  def load_ban
    @ban = UserBan.find_by(id: params[:id])
  end

  def user_ban_params
    params.require(:user_ban).permit(:reason, :note, :enabled, :until, :username, :user_id, :override_ip_ban)
  end

  def modfeed_push(status)
    BanLogger.log(@ban.user.name, current_user.name, status, @ban.until, @ban.reason)
  end
end
