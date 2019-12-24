# frozen_string_literal: true

class Image::Intensity < ApplicationRecord
  self.primary_key = :image_id

  belongs_to :image

  validates :image, uniqueness: true
end
