# frozen_string_literal: true

class Image::Hide < ApplicationRecord
  self.primary_keys = :image_id, :user_id

  belongs_to :image, counter_cache: true
  belongs_to :user

  validates :user_id, uniqueness: { scope: [:image_id] }
end
