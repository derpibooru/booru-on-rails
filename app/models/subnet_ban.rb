# frozen_string_literal: true

class SubnetBan < Ban
  # rolify
  resourcify

  belongs_to :banning_user, inverse_of: :subnet_bans_enacted, class_name: 'User', optional: true
  validates :specification, presence: true

  def self.banned?(address)
    address = IPAddr.new(address) if address.is_a?(String)

    valid.where('specification >>= ?', address.to_cidr).detect(&:enabled) || false
  end

  def id_prefix
    'S'
  end
end
