# frozen_string_literal: true

class CommissionCategoryValidator < ActiveModel::Validator
  def validate(record)
    invalid_categories = record.categories - Commission::CATEGORIES
    invalid_categories.each do |bad|
      record.errors.add(:categories, "#{bad} is not a valid category")
    end

    record.errors.add(:categories, 'must be selected') if record.categories.blank?
  end
end
