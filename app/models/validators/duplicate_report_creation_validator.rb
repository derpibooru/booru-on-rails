# frozen_string_literal: true

class DuplicateReportCreationValidator < ActiveModel::Validator
  def validate(record)
    if record.image.nil?
      record.errors[:base] << I18n.t('duplicate_reports.errors.image_nil')
    elsif record.duplicate_of_image.nil?
      record.errors[:base] << I18n.t('duplicate_reports.errors.target_image_nil')
    elsif record.image.id == record.duplicate_of_image.id
      record.errors[:base] << I18n.t('duplicate_reports.errors.identical_images')
    elsif record.image.is_animated? != record.duplicate_of_image.is_animated?
      record.errors[:base] << I18n.t('duplicate_reports.errors.animated_and_still_image')
    elsif [record.image.image_mime_type, record.duplicate_of_image.image_mime_type].include?('video/webm') && record.image.image_mime_type != record.duplicate_of_image.image_mime_type
      record.errors[:base] << I18n.t('duplicate_reports.errors.webm_and_other')
    elsif DuplicateReport.where(image_id: record.image_id, duplicate_of_image_id: record.duplicate_of_image_id).exists?
      record.errors[:base] << I18n.t('duplicate_reports.errors.target_already_reported')
    end
  end
end
