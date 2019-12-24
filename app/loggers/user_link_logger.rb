# frozen_string_literal: true

class UserLinkLogger < LoggerBase
  def self.log(status, user, mod = nil)
    s = +"[USER LINK: #{status}] for #{user&.name}"
    s += " by #{mod.name}" if mod

    modfeed_send(s)
  end
end
