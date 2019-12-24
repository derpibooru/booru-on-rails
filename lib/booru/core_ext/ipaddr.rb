# frozen_string_literal: true

require 'ipaddr'

class IPAddr
  # Displays this IP address in CIDR form, e.g. '127.0.0.0/16'.
  #
  # @return [String]
  # @example
  #   IPAddr.new('127.0.0.1/24').to_s
  #   #=> '127.0.0.0'
  #
  #   IPAddr.new('127.0.0.1/24').to_cidr
  #   #=> '127.0.0.0/24'
  #
  #   IPAddr.new('2400:cb00:2001:470::1').to_cidr
  #   #=> '2400:cb00:2001:470::1/128'
  #
  #   IPAddr.new('2400:cb00::/32').to_cidr
  #   #=> '2400:cb00::/32'
  #
  def to_cidr
    "#{self}/#{@mask_addr.to_s(2).count('1')}"
  end
end
