# frozen_string_literal: true

class PicartoChannel < Channel
  before_create :fetch

  def url
    "https://picarto.tv/#{short_name}"
  end

  def url=(url)
    self.short_name = if url.include?('http://') || url.include?('https://')
      URI.parse(url).path.split('/')[1]
    else
      url
    end
  end

  def self.update_picarto
    url = 'https://api.picarto.tv/v1/online?adult=true&gaming=true'
    failures = 0
    begin
      loop do
        response = RestClient::Request.execute(url: url, headers: { Accept: 'application/json' }, method: :get, timeout: 3, open_timeout: 3)
        data = JSON.parse(response.body)

        # Reformat (we want name => data)
        data = data.index_by { |h| h['name'] }

        # Update the ones that were live
        PicartoChannel.where(short_name: data.keys).find_each do |pc|
          # Refetch for newly live channels.
          pc.fetch unless pc.is_live

          # TODO: we could get rid of the transaction here but we'd have to also
          # update the notification code (see Channel) to match
          pc.thumbnail_url = data[pc.short_name]['thumbnails']['web']
          pc.viewers = data[pc.short_name]['viewers']
          pc.last_live_at = Time.zone.now
          pc.save
        end

        # Mark off the ones that aren't
        PicartoChannel.where.not(short_name: data.keys).update_all(is_live: false, updated_at: Time.zone.now)

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
    url = "https://api.picarto.tv/v1/channel/name/#{short_name}"
    response = RestClient::Request.execute(url: url, headers: { Accept: 'application/json' }, method: :get, timeout: 3, open_timeout: 3)
    data = JSON.parse(response.body)

    self.title = data['title'].presence || "#{short_name}'s Stream"
    self.is_live = data['online']
    self.nsfw = data['adult']
    self.viewers = data['viewers']
    self.thumbnail_url = data['thumbnails']['web']
    self.last_fetched_at = Time.zone.now

    # get rid of pesky HTML tags
    self.description = nil
  end
end
