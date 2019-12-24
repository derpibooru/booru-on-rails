# frozen_string_literal: true

require 'addressable/uri'
require 'openssl'

module Camo
  def self.image_url(image_url)
    domain = Addressable::URI.parse(image_url).domain
    return image_url if domain&.in?(Booru::CONFIG.settings[:cdn_host]) || !$flipper.enabled?(:camo_images)

    camo_digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Booru::CONFIG.settings[:camo_key], image_url)
    camo_url = "https://#{Booru::CONFIG.settings[:camo_host]}/#{camo_digest}"
    proxied_uri = Addressable::URI.parse(camo_url)
    proxied_uri.query_values = { url: image_url }
    proxied_uri.to_s
  rescue StandardError
    ''
  end
end
