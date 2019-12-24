# frozen_string_literal: true

class Forum < ApplicationRecord
  belongs_to :last_post, class_name: 'Post', optional: true
  belongs_to :last_topic, class_name: 'Topic', optional: true
  has_many :topics
  has_many :notifications, inverse_of: :actor
  has_many :subscriptions, dependent: :delete_all
  has_many :subscribers, through: :subscriptions, source: :user

  resourcify
  validates :name, :short_name, uniqueness: true
  validates :short_name, format: { with: /\A[a-z]+\z/, message: 'must consist only of lowercase letters.' }

  # Update before destruction
  before_destroy do |forum|
    forum.topics.each(&:destroy)
    # Clear notifications
    Notification.mark_all_read(forum)
    Notification.async_cleanup(forum)
  end

  def to_param
    short_name
  end

  def refresh_last_post!
    last_topic = topics.where(hidden_from_users: false).order(last_replied_to_at: :desc).first
    update_columns(last_topic_id: last_topic&.id, last_post_id: last_topic&.last_post&.id)
  end

  def self.get_user_facing_list(user)
    Forum.order(name: :asc).where(access_level: Forum.access_level_for(user.try(:role)))
  end

  def visible_to?(user)
    Forum.access_level_for(user.try(:role)).include?(access_level)
  end

  ROLE_TO_ACCESS_LEVEL = {
    'user'      => %w[normal],
    'assistant' => %w[normal assistant],
    'moderator' => %w[normal assistant staff],
    'admin'     => %w[normal assistant staff]
  }.freeze

  def self.access_level_for(role)
    ROLE_TO_ACCESS_LEVEL.fetch(role, %w[normal])
  end
end
