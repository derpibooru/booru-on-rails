# frozen_string_literal: true

class Commission < ApplicationRecord
  include Reportable

  resourcify

  belongs_to :user
  belongs_to :sheet_image, class_name: 'Image', optional: true
  has_many :commission_items, dependent: :destroy

  CATEGORIES = Booru::CONFIG.commissions[:categories]

  validates :information, presence: true, length: { maximum: 700 }
  validates :contact, presence: true, length: { maximum: 700 }
  validates :will_create, length: { maximum: 700 }
  validates :will_not_create, length: { maximum: 700 }
  validates :open, exclusion: [nil]
  validates :sheet_image, presence: { message: 'must be a valid image ID.' }, if: proc { sheet_image_id.present? }
  validates :user, presence: true, uniqueness: true
  validates_with CommissionCategoryValidator

  before_validation do
    categories.reject!(&:blank?)
  end

  def minimum_price
    commission_items.minimum(:base_price) || 0
  end

  def maximum_price
    commission_items.maximum(:base_price) || 0
  end

  def self.listings_per_page
    15
  end

  def to_param
    user.slug
  end
end
