# frozen_string_literal: true

class Image::Tagging < ApplicationRecord
  self.primary_keys = :image_id, :tag_id

  belongs_to :image
  belongs_to :tag

  validates :tag, uniqueness: { scope: [:image_id] }
end
