# frozen_string_literal: true

require 'ipaddr'

class Admin::SubnetBansController < ApplicationController
  before_action :load_ban, only: [:show, :edit, :update, :destroy]

  def index
    @title = 'Admin - Subnet Bans'
    authorize! :mod_read, SubnetBan
    @bans = if params[:q].present?
      # Only check the PG table if this looks like an IP address
      ip = (IPAddr.new(params[:q]) rescue nil)
      if ip
        SubnetBan.where('specification <<= :ip OR specification >>= :ip', ip: params[:q])
      else
        SubnetBan.where('(generated_ban_id IN (:q)) OR (to_tsvector(reason) @@ plainto_tsquery(:q)) OR (to_tsvector(note) @@ plainto_tsquery(:q))', q: params[:q])
      end
    else
      SubnetBan
    end.order(created_at: :desc).page(params[:page]).per(25)

    respond_to do |format|
      format.html
      format.json { render json: @bans }
    end
  end

  # TODO: Unfinished page
  def show
    @title = "Ban History: #{@ban.specification}"
    authorize! :manage, SubnetBan
  end

  def new
    @title = 'New Subnet Ban'
    authorize! :mod_read, SubnetBan
    @ban = SubnetBan.new
    respond_to do |format|
      format.html
      format.json { render json: @ban }
    end
  end

  def edit
    authorize! :edit, SubnetBan
  end

  def create
    @ban = SubnetBan.new(subnet_ban_params)
    @ban.banning_user = current_user
    authorize! :create, @ban
    respond_to do |format|
      @ban.specification = @ban.specification.mask(64) if @ban.specification.ipv6? # Putting this in a subnet_ban model callback breaks IPAddr in horrible ways.

      if @ban.save
        modfeed_push('new')
        format.html { redirect_to admin_subnet_bans_path, notice: 'Subnet Ban was successfully created.' }
        format.json { render json: @ban, status: :created, location: admin_subnet_bans_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @ban.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :edit, SubnetBan
    respond_to do |format|
      if @ban.update(subnet_ban_params)
        modfeed_push('edited')
        format.html { redirect_to admin_subnet_bans_path, notice: 'Subnet Ban was successfully updated.' }
        format.json { render json: @ban, status: :created, location: admin_subnet_bans_path }
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
      format.html { redirect_to admin_subnet_bans_url }
      format.json { head :ok }
    end
  end

  private

  def subnet_ban_params
    params.require(:subnet_ban).permit(:reason, :note, :enabled, :specification, :until)
  end

  def load_ban
    @ban = SubnetBan.find_by(id: params[:id])
  end

  def modfeed_push(status)
    BanLogger.log(@ban.specification.to_cidr, current_user.name, status, @ban.until, @ban.reason)
  end
end
