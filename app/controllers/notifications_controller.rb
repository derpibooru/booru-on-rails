# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :require_user

  skip_authorization_check

  def index
    @title = 'Notification Area'
    @notifications = current_user.notifications.includes(:actor, :actor_child).page(params[:page]).per(25).order(updated_at: :desc)
  end
end
