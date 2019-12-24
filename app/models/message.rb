# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :from, class_name: 'User', optional: true
  belongs_to :conversation, optional: true

  validates :body, presence: true, length: { maximum: 600_000 }
  validates :from, presence: true

  after_create do
    conversation.from_read       = false
    conversation.to_read         = false
    conversation.last_message_at = Time.zone.now
    conversation.save
  end

  def for_route
    self
  end

  # TODO: create a base class for comments/posts/messages
  alias user from

  def author
    from.name
  end

  def user_visible?
    true
  end
end
