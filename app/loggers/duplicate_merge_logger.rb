# frozen_string_literal: true

class DuplicateMergeLogger < LoggerBase
  def self.log(source, target, user)
    s = +"[IMAGE: Merged ##{source.id}]"
    s += " #{Booru::CONFIG.settings[:public_url_root]}/#{source.id} merged into #{Booru::CONFIG.settings[:public_url_root]}/#{target.id}"
    livefeed_send(s)

    s += " by #{user ? user.name : 'unknown'}"
    modfeed_send(s)
  end
end
