# frozen_string_literal: true

class LivestreamChannel < Channel
  # Returns an escaped hostname for the livestream API for the given short_name
  def self.api_hostname(name)
    "x#{name.tr('_', '-')}x"
  end

  # Returns the API root for a channel short_name
  def self.api_root(name)
    "http://#{api_hostname(name)}.api.channel.livestream.com/2.0"
  end

  # Reconstruct the canonical URI
  def url
    return '' unless short_name && short_name != ''

    'http://www.livestream.com/' + short_name
  end

  # Parse out the short name
  def url=(url_or_sn)
    self.short_name = LivestreamChannel.find_short_name(url_or_sn)
  end

  before_create do |channel|
    channel.next_check_at = Time.zone.now
  end

  # Turns a Livestream page URI or short name into a short name, if possible, or returns false
  def self.find_short_name(url)
    return url unless url.include?('http://') || url.include?('https://')

    uri = URI.parse(url)
    if uri
      sn = uri.path.split('/')[1]
      return sn if sn && sn != ''
    end
    false
  end

  # Helper, returns API root for this given channel
  def api_root
    LivestreamChannel.api_root(short_name)
  end

  def self.get_new_artwork
    LivestreamChannel.find_each do |lc|
      lc.update_columns(channel_image: nil, banner_image: nil)
      lc.fetch
    end
  end

  def self.update_livestreams
    failures = 0
    begin
      loop do
        upd_thr = []
        LivestreamChannel.where('next_check_at < ?', Time.zone.now).limit(20).each do |c|
          # First things first...
          if c.is_live?
            c.update_columns(next_check_at: Time.zone.now + 1.minute + rand(59).seconds)
          else
            c.update_columns(next_check_at: Time.zone.now + 5.minutes + rand(2).minutes + rand(59).seconds)
          end
          # Did someone say embarrasingly parallel IO-blocked task? Threads ho!
          upd_thr << Thread.new(c) do |channel|
            start = Time.zone.now
            logger.info "Channel: Started check of #{channel.title}/#{channel.id}"
            channel.perform_fetch!
            logger.info "Channel: Finished check of #{channel.title}/#{channel.id}, took #{Time.zone.now - start}s"
            channel.update_columns(last_live_at: Time.zone.now) if channel.is_live?
                     rescue StandardError => ex
                       channel.update_columns(is_live: false)
            # logger.warn "Failed check of #{channel.title}/#{channel.id}! #{e.inspect}"
                       logger.warn "Channel: Got exception when processing #{channel.id} - #{ex.inspect}"
                       logger.warn ex.backtrace
          end
        end
        # Wait for that lot to finish updating
        upd_thr.each(&:join)
        # Rate limit
        sleep 0.5
      end
    rescue StandardError => ex
      failures += 1
      # logger.warn "Failure, #{e}"
      # clean up any remaining threads
      logger.warn "Channel: Got exception when performing channel updates! #{e.inspect}"
      logger.warn e.backtrace
      upd_thr.each { |t| Thread.kill(t) }
      # give up if we die too often, probably means we've lost connection to mongo and should restart
      if failures > 10
        raise ex
      else
        sleep 5
        retry
      end
    end
  end

  # Fetches new information for this LivestreamChannel instance
  def fetch
    # atomically set this so we're good to break horribly ahead without enqueueing too often
    return false unless $flipper[:livestream_updates].enabled?

    response = RestClient::Request.execute(url: api_root + '/info.json', method: :get, timeout: 3, open_timeout: 3)
    data = JSON.parse(response.body)

    self.title = data['channel']['title']
    self.description = data['channel']['description']
    self.is_live = data['channel']['isLive']
    self.viewers = data['channel']['currentViewerCount']
    self.viewer_minutes_today = data['channel']['viewerMinutesToday']
    self.viewer_minutes_thisweek = data['channel']['viewerMinutesThisWeek']
    self.viewer_minutes_thismonth = data['channel']['viewerMinutesThisMonth']
    self.total_viewer_minutes = data['channel']['totalViewerMinutes']
    self.title = data['channel']['title']
    self.tags = data['channel']['tags']
  end
end
