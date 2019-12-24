# frozen_string_literal: true

class IpProfiles::TagChangesController < ApplicationController
  before_action :set_state
  before_action :load_tag_changes
  before_action :check_auth

  respond_to :html, :json

  def index
    @ip = params[:ip_profile_id]
    @title = "Tag Changes: #{@ip}"
    respond_with @tag_changes
  end

  private

  def set_state
    if params[:added] == '1'
      @state = true
    elsif params[:added] == '0'
      @state = false
    end
  end

  def load_tag_changes
    @tag_changes = TagChange.where(ip: params[:ip_profile_id]).includes(:image)
    @tag_changes = @tag_changes.where(state: @state) unless @state.nil?
    @tag_changes = @tag_changes.page(params[:page]).per(20)
  end

  def check_auth
    authorize! :mod_read, User
  end
end
