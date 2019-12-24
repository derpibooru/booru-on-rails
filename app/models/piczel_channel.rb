# frozen_string_literal: true

class PiczelChannel < Channel
  before_create :fetch

  def url
    "https://piczel.tv/watch/#{short_name}"
  end

  def url=(url)
    self.short_name = if url.include?('http://') || url.include?('https://')
      URI.parse(url).path.split('/')[2]
    else
      url
    end
  end

  def self.update_piczel
    url = 'https://piczel.tv/api/streams'
    failures = 0
    begin
      loop do
        response = RestClient::Request.execute(url: url, headers: { Accept: 'application/json' }, method: :get, timeout: 3, open_timeout: 3)
        data = JSON.parse(response.body)

        # Reformat (we want name => data)
        data = data.index_by { |h| h['slug'] }

        # Update the ones that were live
        PiczelChannel.where(short_name: data.keys).find_each do |pc|
          # Refetch for newly live channels.
          pc.fetch unless pc.is_live

          # TODO: we could get rid of the transaction here but we'd have to also
          # update the notification code (see Channel) to match
          pc.viewers = data[pc.short_name]['viewers']
          pc.last_live_at = Time.zone.now
          pc.save
        end

        # Mark off the ones that aren't
        PiczelChannel.where.not(short_name: data.keys).update_all(is_live: false, updated_at: Time.zone.now)

        # Refresh every minute so as not to exhaust the API limit
        sleep 60
      end
    rescue StandardError => ex
      failures += 1
      # give up if we die too often
      raise ex if failures > 10

      sleep 5
      retry
    end
  end

  def fetch
    url = "https://piczel.tv/api/streams/#{short_name}"
    response = RestClient::Request.execute(url: url, headers: { Accept: 'application/json' }, method: :get, timeout: 3, open_timeout: 3)
    data = JSON.parse(response.body)

    self.title = data['data'][0]['title'].presence || "#{short_name}'s Stream"
    self.is_live = data['data'][0]['live']
    self.nsfw = data['data'][0]['adult']
    self.viewers = data['data'][0]['viewers']
    self.last_fetched_at = Time.zone.now
    self.thumbnail_url = data['data'][0]['user']['avatar']['avatar']['url']
    self.remote_stream_id = data['data'][0]['id']

    self.description = nil
  end
end
