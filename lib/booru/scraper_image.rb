# frozen_string_literal: true

require 'camo'

module Booru
  # A single image associated with a scraper run.
  class ScraperImage
    # The direct URL of this image.
    # @return [String]
    attr_reader :url

    # An indirect URL of this image throuhg camo, suitable for
    # rendering in-browser.
    # @return [String]
    attr_reader :camo_url

    # Creates a new ScraperImage with the specified parameters.
    def initialize(url:, camo_url: nil)
      @url      = url
      @camo_url = camo_url || Camo.image_url(url)
    end

    # JSON representation of this image pair.
    # @return [Hash]
    def as_json(*)
      {
        url:      url,
        camo_url: camo_url
      }
    end

    def ==(other)
      as_json == other.as_json
    end
  end
end
