# frozen_string_literal: true

require 'dnsbl'
require 'hashie'

module Booru
  class TumblrScraper < Scraper
    INLINE_MATCH = /https?:\/\/(?:\d+\.)?media\.tumblr\.com\/[a-f\d]+\/tumblr(?:_inline)?_[a-z\d]+_\d+\.(?:png|jpe?g|gif)/i.freeze
    URL_MATCH    = /\Ahttps?:\/\/(.*)\/(?:image|post)\/(\d+)(?:\z|[\/?#])/.freeze
    SIZE_MATCH   = /_(\d+)(\..+)$/.freeze
    SIZES        = [1280, 540, 500, 400, 250, 100, 75].freeze
    TUMBLR_IPS   = [
      [IPAddr.new('66.6.32.0/23'), 23],
      [IPAddr.new('66.6.44.0/24'), 24]
    ].freeze

    # Is this a fetchable Tumblr URL?
    # @return [true, false]
    def self.can_handle?(url)
      url.match(URL_MATCH) && tumblr_domain?(Regexp.last_match[1])
    end

    # Determine if this domain name corresponds to a Tumblr-hosted URL.
    #
    # This resolves the given domain name to its IP address and checks
    # if it is a member of the known Tumblr subnets.
    #
    # @return [true, false]
    def self.tumblr_domain?(domain)
      site_ip = IPAddr.new(DNSBL.resolv.getaddress(domain).to_s)
      TUMBLR_IPS.any? { |ip, mask| ip == site_ip.mask(mask) }
    rescue StandardError
      false
    end

    # Try to fetch a Tumblr post from this URL.
    # @return [ScraperInfo]
    def scrape(url)
      domain, post_id = url.match(URL_MATCH)[1..2]

      api_url  = "https://api.tumblr.com/v2/blog/#{domain}/posts/photo?id=#{post_id}&api_key=#{Booru::CONFIG.settings[:tumblr_api_key]}"
      api_resp = request(url: api_url)

      data = Hashie::Mash.new(JSON.parse(api_resp))

      process_post(url, domain, data.response.posts.first)
    end

    private

    # For a given CDN url, finds the URL with the largest fetchable size.
    # @return [String]
    def upsize(image_url)
      return image_url unless image_url.match?(SIZE_MATCH)

      SIZES.map  { |size| image_url.gsub(SIZE_MATCH, "_#{size}\\2") }
           .find { |url| url_ok?(url) }
    end

    # Process a `photo` type API response.
    # @return [Array<ScraperImage>]
    def process_photo(response)
      response.photos.map do |p|
        image   = upsize(p.original_size.url)
        preview = p.alt_sizes.detect { |s| s.width == 400 }&.url || image

        ScraperImage.new(url: image, camo_url: Camo.image_url(preview))
      end
    end

    # Process an arbitrary text segment to return any images potentially
    # embedded in the markup.
    #
    # @return [Array<ScraperImage>]
    def process_text(text)
      text.scan(INLINE_MATCH).map do |image|
        ScraperImage.new(url: upsize(image), camo_url: Camo.image_url(image))
      end
    end

    # Extract images from a `trail` segment in the Tumblr v2 API.
    # @return [Array<ScraperImage>]
    def process_trail(trail)
      trail.map { |c| process_text(c.content_raw) }.flatten
    end

    # Process response data from the Tumblr v2 API.
    #
    # @param url [String] The source URL.
    # @param domain [String] The source domain, treated as the artist name.
    # @param response [Hashie::Mash] Response data.
    #
    # @return [ScraperResult]
    def process_post(url, domain, response)
      images = []

      case response.type
      when 'photo'
        images.concat process_photo(response)
        images.concat process_trail(response.trail) if response.trail?
      when 'text'
        images.concat process_text(response.body)
      end

      if images.any?
        ScraperResult.new(
          source_url:  url,
          author_name: domain.split('.', 2)[0],
          description: response.summary,
          images:      images
        )
      else
        ScraperResult.new(
          errors: [I18n.t('images.errors.scraper_tumblr_post_no_images', type: response.type)]
        )
      end
    end
  end
end
