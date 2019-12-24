# frozen_string_literal: true

module Booru
  class RawImageScraper < Scraper
    # Is this a fetchable raw image URL?
    # @return [true, false]
    def self.can_handle?(url)
      IMAGE_MIME_TYPES.include?(request(url: url, raw: true).headers[:content_type])
    rescue StandardError
      false
    end

    def scrape(url)
      images = [ScraperImage.new(url: url)]

      ScraperResult.new(
        source_url: url,
        images:     images
      )
    end
  end
end
