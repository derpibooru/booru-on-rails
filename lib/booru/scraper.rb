# frozen_string_literal: true

require 'booru/scraper_image'
require 'booru/scraper_result'

module Booru
  # Image scraper base class.
  #
  # To use the scraper, you should call Scraper.scrape_url with the URL
  # you would like to fetch from. The scraper will then return a {ScraperResult}
  # holding information about the image that was fetched.
  #
  # In order to write a new subclass for the scraper, inherit Scraper, and
  # define the class method `can_handle?` and the instance method `scrape`,
  # both of which take the URL as a parameter.
  #
  # @see ScraperResult
  # @see ScraperImage
  class Scraper
    BOORU_UA         = { 'User-Agent' => Booru::CONFIG.settings[:scraper_user_agent] }.freeze
    IMAGE_MIME_TYPES = %w[image/jpeg image/png image/gif image/svg+xml].freeze
    MAX_REDIRECTS    = 3
    TIMEOUT          = 5.seconds
    OK_CODES         = (200..399).freeze

    # Allow subclass instances to access these methods as
    # instance methods.
    delegate :magic, :follow_redirect, :request, :url_ok?, to: :class

    # Get information about any image(s) at this URL.
    #
    # @param url [String] The URL to be scraped.
    # @return [ScraperResult]
    def self.scrape(url)
      url = follow_redirect(url.strip)

      descendants.each do |klass|
        return klass.new.scrape(url) if klass.can_handle?(url)
      end

      ScraperResult.new(errors: [I18n.t('images.errors.scraper_fetch_failed')])
    end

    # Fetch an image as binary data at this URL.
    # @return [String, nil]
    def self.fetch_image(url)
      request(url: url, raw: true).body
    rescue StandardError
      nil
    end

    # Attempt to follow redirects on this URL, up to +MAX_REDIRECTS+ times.
    # Returns the final URL, or the original if there was an error.
    #
    # @param url [String]
    # @return [String]
    def self.follow_redirect(url)
      request(url: url, method: :head).request.url
    rescue StandardError
      url
    end

    # Requests the URL with the specified parameters.
    #
    # @param url [String] URL to fetch
    # @param cookies [Hash] Any cookies
    # @param method [Symbol] The request method to use (:get, :head, ...)
    # @param raw [true, false] True if downloading large files
    #
    # @return [RestClient::Response]
    def self.request(url:, cookies: nil, method: :get, raw: false)
      RestClient::Request.execute(
        headers:       BOORU_UA,
        max_redirects: MAX_REDIRECTS,
        timeout:       TIMEOUT,
        url:           URI.parse(url).to_s,
        cookies:       cookies,
        method:        method,
        raw_request:   raw
      )
    end

    # Check to see if this URL can be successfully fetched.
    #
    # @return [true, false]
    def self.url_ok?(url)
      OK_CODES.cover?(RestClient.head(url).code)
    end

    # Inheritance hook for Scraper.
    def self.inherited(klass)
      descendants << klass
    end

    # Registry of known descendant classes of Scraper.
    def self.descendants
      @descendants ||= []
    end
  end
end
