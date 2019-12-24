# frozen_string_literal: true

class Forum::Subscription < ApplicationRecord
  self.primary_key = :forum_id

  belongs_to :forum
  belongs_to :user

  validates :user, uniqueness: { scope: [:forum_id] }
end
