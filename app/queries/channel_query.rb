# frozen_string_literal: true

class ChannelQuery
  def self.live_and_static_sorted(nsfw)
    if nsfw
      Channel
    else
      Channel.where(nsfw: false)
    end.where.not(last_fetched_at: nil).order('is_live DESC, title ASC')
  end
end
