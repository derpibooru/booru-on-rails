# frozen_string_literal: true

class IpProfiles::SourceChangesController < ApplicationController
  before_action :load_source_changes
  before_action :check_auth

  respond_to :html, :json

  def index
    @ip = params[:ip_profile_id]
    @title = "Source Changes: #{@ip}"
    respond_with @source_changes
  end

  private

  def load_source_changes
    @source_changes = SourceChange.where(ip: params[:ip_profile_id]).includes(:image)
    @source_changes = @source_changes.page(params[:page]).per(20)
  end

  def check_auth
    authorize! :mod_read, User
  end
end
