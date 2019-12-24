# frozen_string_literal: true

class Image::Subscription < ApplicationRecord
  self.primary_key = :image_id

  belongs_to :image
  belongs_to :user

  validates :user, uniqueness: { scope: [:image_id] }
end
