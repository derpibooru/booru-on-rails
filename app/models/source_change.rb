# frozen_string_literal: true

class SourceChange < ApplicationRecord
  include UserAttributable
  belongs_to :image, optional: true

  def user_visible?
    super && !(image.anonymous && image.uploader_is?(user, ip))
  end

  def self.add_to_img(img, updating_user, request, initial: false)
    if img.previous_changes.include? 'source_url'
      SourceChange.create(ip:          request.remote_ip,
                          fingerprint: request.cookies['_ses'],
                          user:        updating_user,
                          image:       img,
                          new_value:   img.source_url,
                          initial:     initial)
    end
  end

  def as_json
    {
      id:       id,
      image_id: image_id,
      initial:  initial,
      value:    new_value,
      user:     author
    }
  end

  delegate :id, to: :parent, prefix: true

  alias parent image
end
