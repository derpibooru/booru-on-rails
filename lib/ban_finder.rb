# frozen_string_literal: true

module BanFinder
  def self.finds_ban_for?(request, current_user = nil, cookies = nil, record_use = false)
    fingerprint = cookies && cookies['_ses']

    key = ['ban-', request.remote_ip]
    key << '-' << current_user.id if current_user
    key << '-' << fingerprint if fingerprint
    key = key.join('')

    Rails.cache.fetch(key, expires_in: 1.minute) do
      xban =
        SubnetBan.banned?(request.remote_ip) ||
        FingerprintBan.banned?(fingerprint)

      if current_user
        if record_use
          UserFingerprint.record_use(current_user, fingerprint)
          UserIp.record_use(current_user, request.remote_ip)
        end

        # Only user bans should apply
        user_ban = UserBan.banned?(current_user)
        user_ban || false
      else
        xban || false
      end
    end
  end
end
