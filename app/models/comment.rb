# frozen_string_literal: true

class Comment < ApplicationRecord
  include Hidable
  include Reportable
  include FancySearchable
  include Indexable
  include AnonUserAttributable
  resourcify

  validates_with CommentValidator
  validates_with DestroyOnlyIfHiddenValidator
  validates :body, presence: { message: "can't be blank.", unless: :destroyed_content }
  validates :edit_reason, length: { maximum: 70, message: 'too long (70 character max).' }
  belongs_to :image, validate: false, optional: true
  belongs_to :deleted_by, class_name: 'User', optional: true
  has_array_field :image_tags, Tag

  has_paper_trail on: [:update, :destroy]

  after_create do
    # Update image comment count.
    Image.increment_counter(:comments_count, image_id)
    image.update(updated_at: Time.zone.now)
  end

  after_commit(on: :create) do
    # Send notifications.
    Notification.async_notify(image, 'commented on', self)
  end

  after_commit :update_index

  def link_to_route
    "/#{image.id}#comment_#{id}"
  end

  def for_route
    [image, self]
  end

  delegate :id, :title, to: :parent, prefix: true

  alias parent image
end
