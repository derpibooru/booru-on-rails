# frozen_string_literal: true

class HidableLogger < LoggerBase
  def self.log(hidable, state, mod, reason = nil)
    body = hidable.body if hidable.respond_to?(:body)

    s =  "[#{hidable.class.to_s.upcase}: #{state}]"
    s += " #{Booru::CONFIG.settings[:public_url_root]}#{hidable.link_to_route}"
    s += " by #{mod}" if mod.present?
    s += " - reason: #{reason}" if reason.present?
    s += " - body: #{sanitize_newlines(body)[0..100]}" if body.present?

    modfeed_send(s)
  end
end
