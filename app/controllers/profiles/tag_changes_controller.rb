# frozen_string_literal: true

class Profiles::TagChangesController < ApplicationController
  before_action :load_state
  before_action :load_user
  before_action :load_tag_changes

  skip_authorization_check

  respond_to :html, :json

  def index
    @title = "Tag Changes for #{@user.name}"
    respond_with @tag_changes
  end

  private

  def load_user
    @user = User.find_by!(slug: params[:profile_id])
  end

  def load_tag_changes
    @tag_changes = if can? :manage, User
      TagChange.where(user_id: @user.id).includes(:image)
    else
      TagChange.where("tag_changes.user_id = ? AND NOT EXISTS (SELECT * FROM images WHERE tag_changes.image_id = images.id AND images.user_id = tag_changes.user_id AND images.anonymous = 't')", @user.id).includes(:image)
    end

    @tag_changes = @tag_changes.where(added: @state) unless @state.nil?
    @tag_changes = @tag_changes.page(params[:page]).per(20)
  end

  def load_state
    if params[:added] == '1'
      @state = true
    elsif params[:added] == '0'
      @state = false
    end
  end
end
