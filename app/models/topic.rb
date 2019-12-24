# frozen_string_literal: true

class Topic < ApplicationRecord
  include Hidable

  resourcify

  belongs_to :forum, inverse_of: :topics, optional: true
  belongs_to :user, optional: true
  belongs_to :locked_by, class_name: 'User', optional: true
  has_many :posts, dependent: :destroy
  belongs_to :last_post, class_name: 'Post', optional: true
  has_one :poll, -> { includes(:options) }, dependent: :destroy, inverse_of: :topic
  has_many :notifications, inverse_of: :actor
  has_many :subscriptions, dependent: :delete_all
  has_many :subscribers, through: :subscriptions, source: :user

  accepts_nested_attributes_for :posts
  accepts_nested_attributes_for :poll, limit: 1, reject_if: proc { |poll| poll['title'].blank? }

  validates :title, presence: true, length: { minimum: 4, maximum: 96, message: 'must be at least 4 and no more than 96 characters long' }
  validates :title, uniqueness: { scope: :forum_id, message: 'matches with an already exising topic' }
  validates :slug, uniqueness: { scope: :forum_id, message: 'is used by another topic' }
  validates :title, exclusion: { in: %w[topics new], message: '%{value} is a reserved word' }
  validates :forum, presence: true

  validates_associated :poll

  paginates_per 50

  after_create do |topic|
    topic.forum.increment!(:topic_count)
    topic.user.increment!(:topic_count) if topic.user
  end

  after_commit(on: :create) do
    Notification.async_notify(forum, 'posted a new topic', self)
  end

  before_destroy do |topic|
    unless topic.hidden_from_users
      topic.forum.decrement!(:topic_count)
      topic.user.decrement!(:topic_count) if topic.user
    end
    # Clear notifications
    Notification.mark_all_read(topic)
    Notification.async_cleanup(topic)
  end

  after_destroy do |topic|
    topic.forum.refresh_last_post!
  end

  # Update after save check - handle soft deletion updating counts
  after_save do |topic|
    if !topic.forum_id.nil? &&
       !topic.forum_id_before_last_save.nil? &&
       topic.forum_id != topic.forum_id_before_last_save
      # If moving between forums
      old_forum = Forum.find(topic.forum_id_before_last_save)
      target_forum = topic.forum
      # Update counts
      post_count = topic.posts.where(hidden_from_users: false).count
      old_forum.decrement!(:topic_count)
      old_forum.decrement!(:post_count, post_count)
      old_forum.refresh_last_post!
      target_forum.increment!(:topic_count)
      target_forum.increment!(:post_count, post_count)
      target_forum.refresh_last_post!
    end
  end

  before_save do |topic|
    topic.slug = Topic.generate_unique_slug(topic.title, topic.forum_id) if topic.slug.nil?
  end

  def title=(new_title)
    super(new_title&.gsub(/\s+/, ' '))
  end

  # Anything pointing to the topic author should go to the original post author
  delegate :best_user_identifier, :author, :user_visible?, to: :first_post

  def first_post
    posts.order(created_at: :asc).first
  end

  # Generate a slug for the given string, checks for uniqueness and appends numbers if needed
  def self.generate_unique_slug(name, forum_id)
    potential_slug = name.to_slug.presence || Time.zone.now.to_s.to_slug
    slug_not_free = true
    idx = 1
    while slug_not_free
      unless Topic.find_by(slug: potential_slug, forum_id: forum_id)
        slug_not_free = false
        return potential_slug
      end
      name = name[0..(-1 - idx.to_s.length)] if idx > 1
      name = "#{name} #{idx}"
      idx += 1
      potential_slug = name.to_slug
    end
  end

  def to_param
    slug
  end

  # The number of posts in the topic, cached.
  # This includes "deleted" but displayed posts.
  def displayed_posts_count
    @displayed_posts_count ||= posts.count
  end

  # Find the last page in the thread
  def last_page
    (displayed_posts_count / Post.posts_per_page.to_f).ceil
  end

  # Get the page index for a given post ID
  def page_for_post(post_id)
    post_index = Post.find(post_id).topic_position
    # fall back to the slow way if we're not able to use topic_position
    post_index = posts.order(created_at: :asc).pluck(:id).index(post_id.to_s) if !post_index
    ((post_index + 1) / Post.posts_per_page.to_f).ceil
  end

  # How many topics should we display per page? Used in views/controllers/etc
  def self.topics_per_page
    25
  end

  def refresh_last_post!
    last_post = posts.where(hidden_from_users: false).order(topic_position: :desc).first
    update_columns(last_post_id: last_post&.id, last_replied_to_at: last_post&.created_at)
  end

  # Moves this topic to the target forum
  def move_to_forum!(target_forum, defer_index: true, priority: :rebuild)
    # Prevent a hard fail where two topics have the same slug
    self.slug = "#{slug}-#{Time.zone.today.yday}" if Forum.where(forum: target_forum).where(slug: slug)

    self.forum = target_forum
    save!
    posts.each do |post|
      post.update_index(defer: defer_index, priority: priority)
    end
  end

  # Resets the topic_position of each post.
  def recount_post_positions!(defer_index: true, index_prio: :high)
    posts.order(created_at: :asc).each_with_index do |post, i|
      post.update_columns(topic_position: i)
      post.update_index(defer: defer_index, priority: index_prio)
    end
  end

  def as_json(*)
    d = {
      id:                 id.to_s,
      slug:               slug.to_s,
      title:              title.to_s,
      sticky:             sticky,
      created_at:         created_at,
      updated_at:         updated_at,
      forum_id:           forum.id.to_s,
      last_replied_to_at: last_replied_to_at.to_s
    }
    d[:deletion_reason] = deletion_reason if hidden_from_users
    if locked_at
      d[:lock_reason] = lock_reason
      d[:locked_at] = locked_at
    end
    d
  end

  def link_to_route
    "/#{forum.short_name}/#{slug}"
  end
end
