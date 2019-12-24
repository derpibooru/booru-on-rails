# frozen_string_literal: true

class Post < ApplicationRecord
  include Hidable
  include Reportable
  include FancySearchable
  include Indexable
  include AnonUserAttributable

  resourcify

  belongs_to :topic, inverse_of: :posts, optional: true
  validates :body,
            presence: { message: "can't be blank.",
                        unless:  proc { |c| c.destroyed_content } }
  validates :body, length: { maximum: 600_000 }
  validates :edit_reason, length: { maximum: 70, message: 'too long (70 character max)' }

  has_paper_trail on: [:update, :destroy]

  validates_with DestroyOnlyIfHiddenValidator

  delegate :forum, to: :topic, prefix: true

  def self.posts_per_page
    25
  end

  paginates_per Post.posts_per_page

  before_create do |post|
    locked_topic = Topic.find(post.topic_id)

    locked_topic.with_lock do
      prev_post = locked_topic.posts.order(topic_position: :desc).first
      post.topic_position = prev_post&.topic_position&.succ || 0
    end
  end

  after_create do |post|
    # Update counters.
    post.topic.update_columns(last_replied_to_at: post.created_at, last_post_id: post.id, post_count: post.topic.post_count + 1)
    post.topic.forum.increment!(:post_count)
    post.topic.forum.update_columns(last_post_id: post.id, last_topic_id: post.topic.id)
  end

  after_commit(on: :create) do
    Notification.async_notify(topic, 'posted a new reply in', self)
  end

  after_commit do
    update_index
  end

  after_destroy do |post|
    post.clean_up_after_deletion! unless post.hidden_from_users
    post.topic.update_columns(updated_at: Time.zone.now)
    RecountPostPositionsJob.perform_later(post.topic_id)
  end

  after_save do |post|
    post.topic.update_columns(updated_at: Time.zone.now)
  end

  # Decrements counts, updates last post, and hides the thread if this is the
  # OP.
  def clean_up_after_deletion!
    topic.refresh_last_post!
    topic.forum.refresh_last_post!
    TopicHider.new(topic, user: deleted_by, reason: deletion_reason).save if first?
  end

  # Predicate indicating whether this is the OP.
  def first?
    topic_position == 0
  end

  def for_route
    [topic_forum, topic, self]
  end

  def link_to_route
    "/#{topic.forum.short_name}/#{topic.slug}/post/#{id}#post_#{id}"
  end

  delegate :id, :title, to: :parent, prefix: true

  alias parent topic
end
