# frozen_string_literal: true

class CommissionItem < ApplicationRecord
  resourcify

  belongs_to :commission, counter_cache: true
  belongs_to :example_image, class_name: 'Image'

  ITEM_TYPES = Booru::CONFIG.commissions[:item_types]

  # Validations
  validates :base_price, numericality: { greater_than_or_equal_to: 0, less_than: 500 }
  validates :item_type, presence: true, inclusion: { in: ITEM_TYPES }
  validates :description, presence: true, length: { maximum: 300 }
  validates :add_ons, length: { maximum: 500 }
  validates :example_image_id, presence: true, numericality: { only_integer: true, less_than_or_equal_to: proc { Image.all.maximum(:id) },
                                                               greater_than_or_equal_to: 0, message: 'must be a valid image ID.' }
end
