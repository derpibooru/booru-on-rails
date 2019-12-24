# frozen_string_literal: true

class TagChange < ApplicationRecord
  include UserAttributable
  belongs_to :image, optional: true
  belongs_to :tag, optional: true
  before_save :set_tag_name_cache

  def user_visible?
    super && !(image && image.anonymous && image.uploader_is?(user, ip))
  end

  def set_tag_name_cache
    self.tag_name_cache = tag.name
  end

  def tag_name
    tag.try(:name) || tag_name_cache
  end

  def revert
    return false unless tag && image

    if added?
      image.remove_tags [tag]
    else
      image.add_tags [tag]
    end
    return false unless image.save

    image.update_index(priority: :rebuild)
  end

  def as_json(*)
    {
      added:    added,
      id:       id,
      image_id: image_id,
      tag_name: tag_name,
      user:     author
    }
  end

  delegate :id, to: :parent, prefix: true

  alias parent image
end
