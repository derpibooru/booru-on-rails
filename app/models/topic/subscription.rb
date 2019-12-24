# frozen_string_literal: true

class Topic::Subscription < ApplicationRecord
  self.primary_key = :topic_id

  belongs_to :topic
  belongs_to :user

  validates :user, uniqueness: { scope: [:topic_id] }
end
