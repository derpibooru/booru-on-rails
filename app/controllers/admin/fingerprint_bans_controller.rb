# frozen_string_literal: true

class Admin::FingerprintBansController < ApplicationController
  before_action :load_ban, only: [:edit, :update, :destroy]

  def index
    @title = 'Admin - Fingerprint Bans'
    authorize! :mod_read, FingerprintBan

    @bans = if params[:q].present?
      FingerprintBan.where('(fingerprint ILIKE ?) OR (generated_ban_id IN (?)) OR (to_tsvector(reason) @@ plainto_tsquery(?)) OR (to_tsvector(note) @@ plainto_tsquery(?))',
                           params[:q] + '%', params[:q], params[:q], params[:q])
    else
      FingerprintBan
    end.order(created_at: :desc).page(params[:page]).per(25)

    respond_to do |format|
      format.html
      format.json { render json: @bans }
    end
  end

  def new
    @title = 'New Fingerprint Ban'
    authorize! :mod_read, FingerprintBan
    @ban = FingerprintBan.new
    respond_to do |format|
      format.html
      format.json { render json: @ban }
    end
  end

  def edit
    @title = "Editing Fingerprint Ban: #{@ban.fingerprint}"
    authorize! :edit, FingerprintBan
  end

  def create
    @ban = FingerprintBan.new(fingerprint_ban_params)
    @ban.banning_user = current_user
    authorize! :create, @ban
    respond_to do |format|
      if @ban.save
        modfeed_push('new')
        format.html { redirect_to admin_fingerprint_bans_path, notice: 'Fingerprint Ban was successfully created.' }
        format.json { render json: @ban, status: :created, location: admin_fingerprint_bans_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @ban.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :edit, FingerprintBan
    respond_to do |format|
      if @ban.update(fingerprint_ban_params)
        modfeed_push('edited')
        format.html { redirect_to admin_fingerprint_bans_path, notice: 'Fingerprint Ban was successfully updated.' }
        format.json { render json: @ban, status: :created, location: admin_fingerprint_bans_path }
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
      format.html { redirect_to admin_fingerprint_bans_url }
      format.json { head :ok }
    end
  end

  private

  def fingerprint_ban_params
    params.require(:fingerprint_ban).permit(:reason, :note, :enabled, :fingerprint, :until)
  end

  def load_ban
    @ban = FingerprintBan.find_by(id: params[:id])
  end

  def modfeed_push(status)
    BanLogger.log(@ban.fingerprint, current_user.name, status, @ban.until, @ban.reason)
  end
end
