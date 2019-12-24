# frozen_string_literal: true

class IpProfilesController < ApplicationController
  def show
    authorize! :mod_read, User
    @ip = params[:id]
    @user_ips = UserIp.where(ip: @ip).order(updated_at: :desc)
    @bans = SubnetBan.where('specification >>= :ip', ip: @ip)
    @title = "#{@ip}'s IP profile"
    respond_to do |format|
      format.html
      format.json { render json: { ip: @ip, user_ips: @user_ips, bans: @bans } }
    end
  end
end
