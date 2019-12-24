# frozen_string_literal: true

require 'securerandom'
class Conversation < ApplicationRecord
  belongs_to :from, class_name: 'User', inverse_of: :started_conversations
  belongs_to :to, class_name: 'User', inverse_of: :received_conversations

  has_many :messages
  validates :title, presence: { message: 'Needs a title.' }, length: { maximum: 200, message: 'Title must be less than 200 characters long' }
  validates :to, presence: { message: 'User not found.' }
  validates :from, presence: true

  accepts_nested_attributes_for :messages, limit: 1

  include Reportable

  before_save do |conversation|
    conversation.set_slug
    conversation.mark_read_if_hidden
  end

  def set_slug
    self.slug ||= SecureRandom.uuid
  end

  def mark_read_if_hidden
    self.to_read = true if to_hidden
    self.from_read = true if from_read
  end

  def recipient=(username)
    self.to_id = User.find_by(name: username)&.id
  end

  def recipient
    to.name rescue ''
  end

  def other_party(user)
    if user.id == to_id
      from
    else
      to
    end
  end

  def other_party_name(user)
    if user.id == to_id
      from.name rescue 'Deleted User'
    else
      to.name rescue 'Deleted User'
    end
  end

  def read_by?(user)
    if user.id == to_id
      to_read
    elsif user.id == from_id
      from_read
    else
      false
    end
  end

  def to_param
    self.slug
  end
end
