# frozen_string_literal: true

require 'twitter'

module Booru
  class TwitterScraper < Scraper
    URL_MATCH = /\Ahttps?:\/\/twitter.com\/([A-Za-z\d_]+)\/status\/([\d]+)\/?/.freeze
    CLIENT    = Twitter::REST::Client.new do |config|
      config.consumer_key    = Booru::CONFIG.settings[:twitter_consumer_key]
      config.consumer_secret = Booru::CONFIG.settings[:twitter_consumer_secret]
    end

    # Is this a fetchable Twitter URL?
    # @return [true, false]
    def self.can_handle?(url)
      url.match?(URL_MATCH)
    end

    # Try to fetch a Twitter status from this URL.
    # @return [ScraperResult]
    def scrape(url)
      author, status_id = url.match(URL_MATCH)[1..2]

      # Fetch the status
      tweet = CLIENT.status(
        status_id,
        trim_user:        true,
        include_entities: true,
        tweet_mode:       'extended'
      )

      tweet_images = tweet.media.select { |m| m.is_a?(Twitter::Media::Photo) }

      # Don't do anything for tweets without any content
      return ScraperResult.new(errors: [I18n.t('images.errors.scraper_twitter_status_no_images')]) if tweet_images.empty?

      # Replace mentions with links
      description = tweet.attrs[:full_text].gsub(/@([a-z\d_]+)/i, '"@\1":https://twitter.com/\1')

      # Fetch image URLs
      images = process_images(description, tweet_images)

      ScraperResult.new(
        source_url:  url,
        author_name: author,
        description: description.squish,
        images:      images
      )
    end

    private

    # Process individual photos in the media collection, removing
    # them in turn.
    #
    # @param description [String] Unfrozen reference to the description.
    # @param images [Array<Twitter::Media::Photo>] Set of photos in this tweet.
    #
    # @return [Array<ScraperImage>]
    def process_images(description, images)
      images.map do |media|
        # Rewrite image URL to HTTPS
        media_url = media.media_url.to_s.sub(/\Ahttp:/, 'https:')
        image     = "#{media_url}:orig"
        preview   = "#{media_url}:small"

        # Remove short URL of image from description
        description.gsub!(media.url, '')

        ScraperImage.new(url: image, camo_url: Camo.image_url(preview))
      end
    end
  end
end
