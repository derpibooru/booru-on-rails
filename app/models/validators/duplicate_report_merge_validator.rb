# frozen_string_literal: true

class DuplicateReportMergeValidator < ActiveModel::Validator
  def validate(record)
    # Duplicate reports for hidden images can be submitted but cannot be accepted.
    record.errors[:base] << I18n.t('duplicate_reports.errors.target_image_hidden') if record.persisted? && record.duplicate_of_image.hidden_from_users
    # Fix ratings before merging
    record.errors[:base] << I18n.t('duplicate_reports.errors.ratings_differ') if record.persisted? && !record.same_rating_tags?
  end
end
