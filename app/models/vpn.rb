# frozen_string_literal: true

class Vpn < ApplicationRecord
  def self.known_vpn?(ip)
    where('ip >>= ?', ip).exists?
  end

  # Repopulate the list of known VPNs.
  def self.repopulate_vpns!
    transaction do
      # Truncate table
      delete_all

      # Detect
      time    = 3.days.ago
      vpns_v4 = detect_ipv4(time)
      vpns_v6 = detect_ipv6(time)

      # Populate
      vpns_v4.each { |r| create!(ip: r.ip) }
      vpns_v6.each { |r| create!(ip: r.ip) }
    end

    true
  end

  # Find IPv4 addresses updated more recently than `time` with more than
  # 5 users in that period.
  def self.detect_ipv4(time)
    UserIp
      .select(:ip)
      .from(UserIp.recent_ipv4(time))
      .group(:ip)
      .having('count(*) > 5')
  end

  # Find IPv6 /64s updated more recently than `time` with more than
  # 5 users in that period.
  def self.detect_ipv6(time)
    UserIp
      .select(:ip)
      .from(UserIp.recent_ipv6(time))
      .group(:ip)
      .having('count(*) > 5')
  end
end
