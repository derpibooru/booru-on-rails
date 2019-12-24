# frozen_string_literal: true

class ImageCloudflarePurgeJob < ApplicationJob
  queue_as :low
  def perform(id, times = 5)
    return true unless Booru::CONFIG.settings[:cloudflare_api_key]

    img = Image.find(id)
    to_expire = []

    if img
      # Add HTTPS protocol to conform to API docs.
      non_hidden = img.image.view_urls(hidden: false).map { |_, url| "https:#{url}" }
      hidden = img.image.view_urls(hidden: true).map { |_, url| "https:#{url}" }
      to_expire = hidden + non_hidden

      RestClient::Request.execute(payload: { 'files' => to_expire }.to_json, url: "https://api.cloudflare.com/client/v4/zones/#{Booru::CONFIG.settings[:cloudflare_zone_id]}/purge_cache", method: :delete, timeout: 3, open_timeout: 3, headers: {
        'X-Auth-Key'   => Booru::CONFIG.settings[:cloudflare_api_key],
        'X-Auth-Email' => Booru::CONFIG.settings[:cloudflare_email],
        'Content-Type' => 'application/json'
      })
    end
  rescue StandardError => ex
    sleep 5
    retry if (times -= 1) > 0
    raise ex
  end
end
