# frozen_string_literal: true

class UserBan < Ban
  # rolify
  resourcify

  belongs_to :user, inverse_of: :bans, optional: true
  belongs_to :banning_user, inverse_of: :user_bans_enacted, class_name: 'User', optional: true

  validates :user, presence: true

  after_create :make_ip_ban

  def make_ip_ban
    ip = user.current_sign_in_ip

    return if ip == '127.0.0.1' || override_ip_ban

    if SubnetBan.valid.where('specification >>= ?', ip.to_cidr).empty?
      # Putting this in a subnet_ban model callback breaks IPAddr in horrible ways.
      ip = ip.mask(64) if ip.ipv6?

      SubnetBan.create(valid_until: valid_until, reason: reason, specification: ip, banning_user: banning_user, note: "UserBan created IP ban for #{[username, note].join('-')}")
      BanLogger.log(ip.to_cidr, "UserBan system (#{username})", 'new', self.until, reason)
    end
  end

  def self.banned?(user)
    ban = valid.where(user_id: user.id).detect(&:enabled)
    if ban
      # If we're banned, make sure we additionally ban this IP address.
      ban.make_ip_ban unless SubnetBan.banned?(user.current_sign_in_ip)
      return ban
    end
    false
  end

  def username=(name)
    self.user = User.find_by(name: name)
  end

  def username
    user.name rescue nil
  end

  def id_prefix
    'U'
  end
end
