# frozen_string_literal: true

class BadgeLogger < LoggerBase
  def self.log(name, state, mod, user = nil)
    s = +"[BADGE: #{state}] #{name}"
    s += " on #{user.name}" if user
    s += " by #{mod.name}" if mod

    modfeed_send(s)
  end
end
