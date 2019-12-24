# frozen_string_literal: true

class UserIp < ApplicationRecord
  include ActiveRecord::Sanitization::ClassMethods

  belongs_to :user, optional: true
  validates :user_id, uniqueness: { scope: :ip }

  # Find IPv4 addresses updated more recently than `time`.
  def self.recent_ipv4(time)
    select(:ip)
      .where('family(ip) = 4 AND updated_at > ?', time)
  end

  # Find IPv6 /64s updated more recently than `time`.
  def self.recent_ipv6(time)
    select('network(set_masklen(ip, 64)) as ip')
      .where('family(ip) = 6 AND updated_at > ?', time)
  end

  def self.record_use(user, ip)
    # don't try to record nil users/ips as it would fail
    return if user.nil? || ip.blank?

    UserIp.upsert_all(
      [ip: ip, user_id: user.id],
      unique_by: [:ip, :user_id],
      set:       'uses = user_ips.uses + 1, updated_at = now()'
    )
  end
end
