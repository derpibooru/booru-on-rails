# frozen_string_literal: true

class NotificationJob < ApplicationJob
  queue_as :low

  def perform(actor_id, actor_class, action, actor_child_id = nil, actor_child_class = nil)
    ApplicationRecord.transaction do
      actor = Object.const_get(actor_class).find(actor_id)
      actor_child = actor_child_id && actor_child_class ? Object.const_get(actor_child_class).find(actor_child_id) : nil

      next if actor.subscriptions.empty?

      # Don't push to the user that created the notification
      user_id     = actor_child.try(:user_id) if actor_child
      subscribers = actor.subscribers.where.not(id: user_id)

      notification = Notification.find_or_initialize_by(actor: actor)
      notification.update!(actor_child: actor_child, action: action)

      # Insert the notification to any watchers without it
      UnreadNotification.insert_all(
        subscribers.select(:id, notification.id),
        columns: [:user_id, :notification_id]
      )
    end
  end
end
