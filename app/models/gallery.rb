# frozen_string_literal: true

class Gallery < ApplicationRecord
  include FancySearchable
  include Indexable
  include Reportable
  resourcify

  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :thumbnail, class_name: 'Image'

  has_many :gallery_interactions
  has_many :images, through: :gallery_interactions
  has_many :subscriptions, dependent: :delete_all
  has_many :subscribers, through: :subscriptions, source: :user

  validates :title, presence: true
  validates :spoiler_warning, length: { maximum: 20 }
  validates :description, length: { maximum: Booru::CONFIG.settings[:max_comment_length] }

  after_save :update_index

  before_destroy :removal_clean_up

  def after_subscription_change
    update_index
  end

  def position_order
    order_position_asc ? :asc : :desc
  end

  def add(image)
    gallery_interactions.create(image: image, position: last_position + 1)
    update_columns(image_count: image_count + 1, updated_at: Time.zone.now)
    reindex image
    update_index
    Notification.async_notify(self, 'added images to')
    self
  end

  def remove(image)
    gallery_interactions.find_by(image: image).destroy
    update_columns(image_count: image_count - 1, updated_at: Time.zone.now)
    reindex image
    update_index
    self
  end

  private

  def removal_clean_up
    to_reindex = images.map(&:id)
    gallery_interactions.destroy_all
    BulkIndexUpdateJob.perform_later('Image', to_reindex)
  end

  def reindex(image)
    image.update_index
  end

  def last_position
    gallery_interactions&.maximum(:position) || -1
  end
end
