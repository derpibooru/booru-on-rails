# frozen_string_literal: true

class Channel < ApplicationRecord
  include Reportable

  resourcify

  file :channel_image,
    store_dir:  Booru::CONFIG.settings[:channel_images_file_path],
    url_prefix: Booru::CONFIG.settings[:channel_images_url_prefix]

  file :banner_image,
    store_dir:  Booru::CONFIG.settings[:channel_banners_file_path],
    url_prefix: Booru::CONFIG.settings[:channel_banners_url_prefix]

  validates :short_name, presence: true
  belongs_to :associated_artist_tag, class_name: 'Tag', optional: true
  has_many :notifications, as: :actor
  has_many :subscriptions, dependent: :delete_all
  has_many :subscribers, through: :subscriptions, source: :user

  def self.get_subclass(url)
    if url.include?('livestream.com')
      LivestreamChannel
    elsif url.include?('picarto.tv')
      PicartoChannel
    elsif url.include?('piczel.tv')
      PiczelChannel
    elsif url.include?('twitch.tv')
      TwitchChannel
    else
      raise NotImplementedError, "The url #{url} represents an unimplemented channel provider"
    end
  end

  after_save do |channel|
    # if live state just changed
    if channel.is_live != channel.is_live_in_database
      if channel.is_live
        # if we're now live, send notification
        Notification.async_notify(channel, 'started streaming', nil)
      else
        # if we're now off-air, remove notifications
        Notification.async_cleanup(channel)
      end
    end
  end

  def url
    ''
  end

  def url=(_url_or_sn)
    raise NotImplementedError
  end

  def artist_tag
    associated_artist_tag.try(:name).to_s
  end

  def artist_tag=(tag_name)
    self.associated_artist_tag = Tag.find_by(name: tag_name) if tag_name.present?
  end

  def self.perform_updates
    Thread.new { LivestreamChannel.update_livestreams }
    Thread.new { PiczelChannel.update_piczel }
    Thread.new { TwitchChannel.update_twitch }
    PicartoChannel.update_picarto
  end

  # Perform a fetch and save the model
  def perform_fetch!
    fetch
    # if all is well, record that we succeeded
    self.last_fetched_at = Time.zone.now
    save
  rescue RestClient::ResourceNotFound
    logger.error "Channel #{id} '#{title}' not found"
  end

  # Fetches new information for this LivestreamChannel instance
  def fetch
    raise NotImplementedError
  end
end
