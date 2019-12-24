# frozen_string_literal: true

class FingerprintProfiles::TagChangesController < ApplicationController
  before_action :set_state
  before_action :load_tag_changes
  before_action :check_auth

  respond_to :html, :json

  def index
    @fingerprint = params[:fingerprint_profile_id]
    @title = "Tag Changes: #{@fingerprint}"
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
    @tag_changes = TagChange.where(fingerprint: params[:fingerprint_profile_id]).includes(:image)
    @tag_changes = @tag_changes.where(state: @state) unless @state.nil?
    @tag_changes = @tag_changes.page(params[:page]).per(20)
  end

  def check_auth
    authorize! :mod_read, User
  end
end
