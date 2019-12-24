# frozen_string_literal: true

require 'resolv'

module DNSBL
  LIST = 'xbl.spamhaus.org'

  def self.high_risk?(ip, current_user = nil)
    return false if current_user
    return "Welcome, Tor hidden service user! You'll need to log in to use the site." if ip == '127.0.0.1'

    rev_ip = ip.split('.').reverse.join('.')
    key = "ip-dnsbl7:#{rev_ip}"
    ret = $redis.get(key)

    if ret.nil?
      addr = DNSBL.resolv.getaddress("#{rev_ip}.#{LIST}").to_s rescue nil

      # also check VPN list
      addr ||= Vpn.known_vpn?(ip)

      ret = if addr
        "Sorry, you're connecting from a high-risk IP address. You'll have to log in to use the site's features!"
      else
        false
      end

      $redis.setex(key, 24.hours.to_i, ret)
      ret
    else
      # The redis client does not remarshal values
      ret == 'false' ? false : ret
    end
  end

  # You are not high risk in development
  if Rails.env.development?
    def self.high_risk?(*)
      false
    end
  end

  def self.resolv
    Thread.current[:dnsbl_resolv] ||= Resolv::DNS.new.tap do |r|
      r.timeouts = [1, 2]
    end
  end
end
