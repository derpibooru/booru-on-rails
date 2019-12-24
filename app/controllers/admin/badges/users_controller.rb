# frozen_string_literal: true

class Admin::Badges::UsersController < ApplicationController
  before_action :check_auth
  before_action :load_badge
  before_action :load_users

  def index
    @title = "Users with Badge: #{@badge.title}"
    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  private

  def check_auth
    authorize! :mod_read, Badge
  end

  def load_badge
    @badge = Badge.find(params[:badge_id])
  end

  def load_users
    @users = @badge.users.page(params[:page]).per(50)
  end
end
