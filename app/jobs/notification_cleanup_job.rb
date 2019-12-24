# frozen_string_literal: true

class NotificationCleanupJob < ApplicationJob
  queue_as :low
  def perform(actor_id, actor_class)
    actor = Object.const_get(actor_class).find(actor_id)
    Notification.where(actor: actor).delete_all
  end
end
