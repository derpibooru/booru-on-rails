# frozen_string_literal: true

class TwitchChannel < Channel
  before_create :fetch

  def url
    "https://www.twitch.tv/#{short_name}"
  end

  def url=(url)
    self.short_name = if url.include?('http://') || url.include?('https://')
      URI.parse(url).path.split('/')[1]
    else
      url
    end
  end

  def self.update_twitch
    client = setup_client

    failures = 0
    begin
      loop do
        # Since most Twitch streamers are probably not linked to Derpi we get a list
        # of all channels that we track & pass it to the Twitch API
        channel_ids = TwitchChannel.pluck(:remote_stream_id)

        all_streams = channel_ids.each_slice(100).flat_map do |ids|
          client.get_streams(user_id: ids, first: 100).data
        end

        # Reformat (we want user_id => data)
        all_streams = all_streams.index_by { |stream| stream.user_id.to_i }

        # Update the ones that were live
        TwitchChannel.where(remote_stream_id: all_streams.keys).find_each do |ch|
          # Re-fetch for newly live channels.
          ch.fetch unless ch.is_live

          ch.set_title(all_streams[ch.remote_stream_id])
          ch.viewers = all_streams[ch.remote_stream_id].viewer_count
          ch.last_live_at = Time.zone.now
          ch.save
        end

        # Mark off the ones that aren't
        TwitchChannel.where.not(remote_stream_id: all_streams.keys).update_all(is_live: false, updated_at: Time.zone.now)

        # Refresh every minute so as not to exhaust the API limit
        sleep 60
      end
    rescue StandardError => ex
      Rails.logger.error ex.inspect
      failures += 1
      # give up if we die too often
      raise e if failures > 10

      sleep 5
      retry
    end
  end

  def self.setup_client
    Twitch::Client.new(client_id: Booru::CONFIG.settings[:twitch_public_key])
  end

  def fetch
    client = TwitchChannel.setup_client

    if remote_stream_id.nil?
      user_data = client.get_users(login: short_name).data[0]
      self.remote_stream_id = user_data.id
    else
      user_data = client.get_users(id: remote_stream_id).data[0]
    end

    stream_data = client.get_streams(user_id: remote_stream_id, first: 1).data[0]
    self.is_live = !stream_data.nil?
    self.viewers = is_live ? stream_data.viewer_count : 0
    set_title(stream_data)
    self.last_fetched_at = Time.zone.now
    self.short_name = user_data.display_name

    self.description = nil
  end

  def set_title(data)
    self.title = data.title || "#{short_name}'s Stream"
  end
end
