# frozen_string_literal: true

class NewTopicLogger < LoggerBase
  def self.log(topic)
    s = +"[TOPIC: New] #{Booru::CONFIG.settings[:public_url_root]}#{topic.link_to_route}"
    s += " by #{topic.author}"
    s += " - title: #{sanitize_newlines(topic.title)}"

    livefeed_send(s)
  end
end
