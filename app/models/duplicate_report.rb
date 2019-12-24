# frozen_string_literal: true

require 'dupe_tools'

class DuplicateReport < ApplicationRecord
  include DupeTools

  belongs_to :user, optional: true
  belongs_to :image, class_name: 'Image', inverse_of: nil, optional: true
  belongs_to :duplicate_of_image, class_name: 'Image', inverse_of: nil, optional: true
  belongs_to :modifier, class_name: 'User', inverse_of: nil, optional: true

  resourcify

  validates_with DuplicateReportMergeValidator
  validates_with DuplicateReportCreationValidator, on: :create

  # Run deduplicator(s) and generate report objects
  def self.generate_reports(new_image)
    new_image.detect_duplicates.each do |dupe_image|
      next if dupe_image.id == new_image.id

      DuplicateReport.create image: new_image, duplicate_of_image: dupe_image,
                             reason: 'Automated Perceptual dedupe match', user: nil
    end
  end

  def accept!(user)
    duplicate_of_image.tag_input = duplicate_of_image.tag_list + ',' + image.tag_list
    if duplicate_of_image.valid? && valid?
      image.duplicate_reports.where(state: 'open').update_all(state: 'rejected')
      duplicate_of_image.duplicate_reports.where(duplicate_of_image: image).update_all(state: 'rejected')
      update modifier: user, state: 'accepted'

      DuplicateMergeLogger.log(image, duplicate_of_image, user)
      Notification.async_notify duplicate_of_image, "merged image ##{image_id}"
      ImageDuplicateMergeJob.perform_later image_id, duplicate_of_image_id, user.id
      true
    else
      errors[:base] << "Image to keep: #{duplicate_of_image.errors.full_messages.first}"
      false
    end
  end

  def claim!(user)
    update_columns modifier_id: user.id, state: 'claimed'
  end

  def reject!(user)
    update_columns modifier_id: user.id, state: 'rejected'

    image.duplication_checked = true
    image.duplicate_id = nil
    ImageUnhider.new(image).save
    true
  end
end
