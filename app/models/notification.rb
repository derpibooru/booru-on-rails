# frozen_string_literal: true

# Represents an event on an actor.
class Notification < ApplicationRecord
  belongs_to :actor, polymorphic: true, optional: true
  belongs_to :actor_child, polymorphic: true, optional: true
  belongs_to :user, inverse_of: :created_notifications, optional: true

  # On a notifyable actor
  # has_many :notifications, inverse_of: :actor
  # has_many :subscriptions
  # has_many :subscribers, through: :subscriptions, source: :user

  # Asynchronously kick off a notification
  def self.async_notify(actor, action, actor_child = nil)
    return if actor.nil?

    # Merges have no child
    if actor_child
      NotificationJob.perform_later(actor.id, actor.class.to_s, action, actor_child.id, actor_child.class.to_s)
    else
      NotificationJob.perform_later(actor.id, actor.class.to_s, action)
    end
  end

  # Remove any and all notifications associated with an actor, asynchronously
  def self.async_cleanup(actor)
    NotificationCleanupJob.perform_later(actor.id, actor.class.to_s)
  end

  # Remove notifications for an actor from a user's list
  def self.mark_read(notification, user)
    UnreadNotification.where(notification: notification, user: user).delete_all
  end

  # Remove all notifications for an actor
  def self.mark_all_read(actor, user = nil)
    if user
      UnreadNotification.where(notification_id: Notification.where(actor: actor).select(:id), user: user).delete_all
    else
      UnreadNotification.where(notification_id: Notification.where(actor: actor).select(:id)).delete_all
    end
  end

  def self.trim_old_notifications
    Notification.where('updated_at < ?', 31.days.ago).delete_all
  end

  # Set up a user to receive notifications
  def self.watch(actor, user)
    return if user.cannot?(:read, actor)

    actor.subscriptions.create(user: user)
    actor.after_subscription_change if actor.respond_to?(:after_subscription_change)
  end

  # Stop sending a user notifications
  def self.unwatch(actor, user)
    return if user.cannot?(:read, actor)

    actor.subscriptions.where(user: user).delete_all
    actor.after_subscription_change if actor.respond_to?(:after_subscription_change)
  end

  # Is the user watching this actor?
  def self.watching?(actor, user)
    actor.subscribers.exists?(user.id)
  end
end
