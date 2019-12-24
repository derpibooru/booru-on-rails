# frozen_string_literal: true

class TagLogger < LoggerBase
  def self.log(name, state, msg, mod = nil)
    s = +"[TAG: #{state}] #{name}"
    s += ": #{msg}" if msg.present?
    s += " by #{mod.name}" if mod

    modfeed_send(s)
  end
end
