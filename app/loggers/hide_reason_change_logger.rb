# frozen_string_literal: true

class HideReasonChangeLogger < LoggerBase
  def self.log(image, user)
    s = +"[IMAGE: Hide reason changed ##{image.id}] #{Booru::CONFIG.settings[:public_url_root]}#{image.link_to_route} by #{user&.name}"
    s += " - new reason: #{image.deletion_reason}"

    modfeed_send(s)
  end
end
