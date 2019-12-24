# frozen_string_literal: true

class UserFingerprint < ApplicationRecord
  include ActiveRecord::Sanitization::ClassMethods

  belongs_to :user, optional: true
  validates :user_id, uniqueness: { scope: :fingerprint }

  def self.record_use(user, fingerprint)
    # don't try to record nil users/fingerprints as it would fail
    return if user.nil? || fingerprint.blank?

    UserFingerprint.upsert_all(
      [fingerprint: fingerprint, user_id: user.id],
      unique_by: [:fingerprint, :user_id],
      set:       'uses = user_fingerprints.uses + 1, updated_at = now()'
    )
  end
end
