# frozen_string_literal: true

class Badge < ApplicationRecord
  resourcify

  # Association
  has_many :badge_awards, dependent: :restrict_with_error
  has_many :users, through: :badge_awards
  validates :image, presence: true

  file :image,
    store_dir:  Booru::CONFIG.settings[:badges_file_path],
    url_prefix: Booru::CONFIG.settings[:badges_url_prefix]

  file_validator :image,
    validator: :image_validator,
    mime:      %w[image/png image/svg+xml]

  def as_json(*)
    { image_url: uploaded_image.url, title: title }
  end
end
