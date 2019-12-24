# frozen_string_literal: true

class Channel::Subscription < ApplicationRecord
  self.primary_key = :channel_id

  belongs_to :channel
  belongs_to :user

  validates :user, uniqueness: { scope: [:channel_id] }
end
