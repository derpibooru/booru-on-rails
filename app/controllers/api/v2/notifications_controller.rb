# frozen_string_literal: true

class Api::V2::NotificationsController < Api::V2::ApiController
  skip_authorization_check
  before_action :require_user
  before_action :load_actor, only: [:watch, :unwatch]

  def unread
    render jsonapi: current_user.notifications
  end

  def mark_read
    notification = Notification.find_by(id: params[:id])
    return head(404) if notification.nil?

    Notification.mark_read(notification, current_user)
    respond_with head: :ok
  end

  def watch
    Notification.watch(@actor, current_user)
    respond_with head: :ok
  end

  def unwatch
    Notification.mark_all_read(@actor, current_user)
    Notification.unwatch(@actor, current_user)
    respond_with head: :ok
  end

  private

  def load_actor
    # nastiness-proof constantizer
    actor_class = %w[Image Topic LivestreamChannel Channel Forum Gallery].detect { |cn| params[:actor_class] == cn }.constantize
    @actor = actor_class.find_by(id: params[:id])
    head(404) if @actor.nil?
  end
end
