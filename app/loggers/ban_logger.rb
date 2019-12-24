# frozen_string_literal: true

class BanLogger < LoggerBase
  def self.log(spec, mod, status, valid_until, reason)
    s = +"[BAN: #{status}] on #{spec}"
    s += " by #{mod}"
    s += " - valid until #{valid_until}"
    s += " - reason: #{reason}"

    modfeed_send(s)
  end
end
