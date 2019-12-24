# frozen_string_literal: true

class GalleryInteraction < ApplicationRecord
  belongs_to :image, optional: true
  belongs_to :gallery, optional: true

  def image_index
    {
      id:       gallery_id,
      position: position
    }
  end
end
