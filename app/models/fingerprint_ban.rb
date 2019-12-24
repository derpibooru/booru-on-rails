# frozen_string_literal: true

class FingerprintBan < Ban
  # rolify
  resourcify

  belongs_to :banning_user, inverse_of: :fingerprint_bans_enacted, class_name: 'User', optional: true
  validates :fingerprint, presence: true

  def self.valid_fingerprint?(fingerprint)
    fingerprint && fingerprint =~ /c[0-9]{1,10}/
  end

  def self.banned?(fingerprint)
    fingerprint && valid.find_by(fingerprint: fingerprint, enabled: true)
  end

  def id_prefix
    'F'
  end
end
