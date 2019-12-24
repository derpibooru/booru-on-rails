# frozen_string_literal: true

class Gallery::Subscription < ApplicationRecord
  self.primary_key = :gallery_id

  belongs_to :gallery
  belongs_to :user

  validates :user, uniqueness: { scope: [:gallery_id] }
end
