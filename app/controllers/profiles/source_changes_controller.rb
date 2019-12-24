# frozen_string_literal: true

class Profiles::SourceChangesController < ApplicationController
  before_action :load_user
  before_action :load_source_changes

  skip_authorization_check

  respond_to :html, :json

  # GET /profiles/:profile_id/source_changes
  def index
    @title = "Source Changes for #{@user.name}"
    respond_with @source_changes
  end

  private

  def load_user
    @user = User.find_by!(slug: params[:profile_id])
  end

  def load_source_changes
    @source_changes = if can? :manage, User
      SourceChange.where(user: @user).includes(:image)
    else
      SourceChange.where("source_changes.user_id = ? AND NOT EXISTS (SELECT * FROM images WHERE source_changes.image_id = images.id AND images.user_id = source_changes.user_id AND images.anonymous = 't')", @user.id).includes(:image)
    end.page(params[:page]).per(20)
  end
end
