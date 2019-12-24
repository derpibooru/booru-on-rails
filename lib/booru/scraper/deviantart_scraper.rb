# frozen_string_literal: true

require 'addressable'
require 'hashie'
require 'nokogiri'

module Booru
  class DeviantartScraper < Scraper
    COOKIES = { agegate_state: '1' }.freeze
    NOENTRY = /(?:noentrythumb-\d+\.png|card_black_large.png)\z/.freeze

    # Is this a fetchable DeviantART URL?
    # @return [true, false]
    def self.can_handle?(url)
      Addressable::URI.parse(url).host.end_with?('deviantart.com')
    end

    # Try to fetch a DeviantART post from this URL.
    # @return [ScraperResult]
    def scrape(url)
      resp = request(url: url, cookies: COOKIES)
      page = Nokogiri::HTML(resp.body, nil, 'UTF-8')

      # Fetch image and thumbnail
      images = fetch_image(url, page, resp.cookies)

      # Preserve newlines after HTML tags are stripped
      page.css('br').each { |node| node.replace("\n") }

      author_name = page.at_css('a.username,a[data-username]')&.text&.strip
      author_name = author_name.sub(/\Asee more by /i, '') if author_name

      description = page.at_css('.dev-description,.legacy-journal')&.text&.strip&.chomp

      ScraperResult.new(
        source_url:  url,
        author_name: author_name,
        description: description,
        images:      images
      )
    end

    private

    # Fetches a full size and preview image URL, given a valid DeviantART page.
    #
    # @param url [String] the URL
    # @param page [Nokogiri::HTML] parsed HTML at the URL
    # @param cookies [Hash] cookies from the last request
    #
    # @return [Array<ScraperImage>]
    def fetch_image(url, page, cookies)
      download_link = page.at_css('.dev-page-download,a[download]')
      preview_url   = page.at('meta[@property="og:image"]')['content']
      image_url     = nil

      if download_link
        # Don't know what type of image this is, try to make sure
        # it's a valid image before passing it on
        image = request(url: download_link['href'], cookies: cookies, raw: true)
        image_url = image.request.url if IMAGE_MIME_TYPES.include?(image.headers[:content_type])
      else
        # Downloads are disabled for this image, do the best we can
        image_url   = page.at_css('.dev-content-full')['src'] rescue nil
        image_url ||= page.at_css('[data-hook="art-stage"] img') rescue nil
      end

      # Failed to find something useful, fall back to oEmbed
      if image_url.nil? || preview_url.match?(NOENTRY)
        api_resp      = oembed(url)
        preview_url   = api_resp.url || api_resp.fullsize_url
        image_url   ||= api_resp.fullsize_url || api_resp.url
      end

      [ScraperImage.new(url: image_url, camo_url: Camo.image_url(preview_url))]
    end

    # Fetches oEmbed data from DeviantART. Fallback method if page
    # scraping fails.
    #
    # @return [Hashie::Mash]
    def oembed(url)
      response = request(
        url:     'https://backend.deviantart.com/oembed?url=' + URI.encode_www_form_component(URI.parse(url).to_s),
        cookies: COOKIES
      )

      Hashie::Mash.new(JSON.parse(response))
    end
  end
end
