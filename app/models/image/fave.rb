# frozen_string_literal: true

class Image::Fave < ApplicationRecord
  self.primary_keys = :image_id, :user_id

  belongs_to :image, counter_cache: :faves_count
  belongs_to :user

  validates :user_id, uniqueness: { scope: [:image_id] }

  after_create do
    user.inc_stat(:images_favourited)
  end

  after_destroy do
    user.dec_stat(:images_favourited)
  end
end
