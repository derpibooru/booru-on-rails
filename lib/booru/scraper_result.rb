# frozen_string_literal: true

module Booru
  # Holds information about a scraper run.
  # @see Scraper
  class ScraperResult
    # Errors occurring during scraper execution.
    # @return [Array<String>]
    attr_reader :errors

    # The source URL. This is usually the URL provided,
    # after any redirects have been resolved.
    # @return [String]
    attr_reader :source_url

    # The author's name.
    # @return [String]
    attr_reader :author_name

    # An optional description. Should not contain any
    # HTML, if present.
    # @return [String]
    attr_reader :description

    # The images associated with a scraper run.
    # @return [Array<ScraperImage>]
    attr_reader :images

    # Creates a new ScraperResult with the specified parameters.
    def initialize(errors: [], source_url: nil, author_name: nil, description: nil, images: [])
      @errors      = errors
      @source_url  = source_url
      @author_name = author_name
      @description = description
      @images      = images
    end

    # JSON representation of this result.
    # @return [Hash]
    def as_json(*)
      {
        errors:      errors,
        source_url:  source_url,
        author_name: author_name,
        description: description,
        images:      images.as_json
      }
    end

    # Default equality test. True if all attributes are equal.
    # @return [true, false]
    def ==(other)
      as_json == other.as_json
    end
  end
end
