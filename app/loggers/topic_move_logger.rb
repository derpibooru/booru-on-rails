# frozen_string_literal: true

class TopicMoveLogger < LoggerBase
  def self.log(topic, old_forum, new_forum, mod)
    s =  '[TOPIC: MOVED]'
    s += " #{Booru::CONFIG.settings[:public_url_root]}#{topic.link_to_route}"
    s += " from #{old_forum} to #{new_forum}"
    s += " by #{mod}" if mod.present?

    modfeed_send(s)
  end
end
