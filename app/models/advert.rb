# frozen_string_literal: true

class Advert < ApplicationRecord
  resourcify

  validates :title, presence: true
  validates :link, presence: true
  validates :start_date, presence: true
  validates :finish_date, presence: true
  validates :image, presence: true

  RESTRICTIONS = [
    ['Display on all images', 'none'],
    ['Display on NSFW images only', 'nsfw'],
    ['Display on SFW images only', 'sfw']
  ].freeze

  file :image,
    store_dir:  Booru::CONFIG.settings[:adverts_file_path],
    url_prefix: Booru::CONFIG.settings[:adverts_url_prefix]

  file_validator :image,
    validator: :image_validator,
    mime:      %w[image/png image/jpeg image/gif],
    size:      0..500.kilobytes,
    width:     699..729,
    height:    79..91

  def start=(sometime)
    self.start_date = Chronic.parse(sometime)
  end

  def start
    start_date.to_s
  end

  def finish=(sometime)
    self.finish_date = Chronic.parse(sometime)
  end

  def finish
    finish_date.to_s
  end
end
