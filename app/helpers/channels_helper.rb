# frozen_string_literal: true

require 'camo'

module ChannelsHelper
  def channel_image(channel)
    camo_url = case channel
    when LivestreamChannel
      Camo.image_url("https://thumbnail.api.livestream.com/thumbnail?name=#{channel.short_name}&rand=#{Time.zone.now.to_i}")
    when PicartoChannel
      Camo.image_url(channel.thumbnail_url.presence || 'https://picarto.tv/images/missingthumb.jpg')
    when PiczelChannel
      Camo.image_url("https://piczel.tv/api/thumbnail/stream_#{channel.remote_stream_id}.jpg")
    when TwitchChannel
      Camo.image_url("https://static-cdn.jtvnw.net/previews-ttv/live_user_#{channel.short_name.downcase}-320x180.jpg")
    else
      'no_avatar_original.svg'
    end

    image_tag camo_url, alt: "#{channel.title}'s live thumbnail"
  end
end
