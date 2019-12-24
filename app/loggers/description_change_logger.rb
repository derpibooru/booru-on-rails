# frozen_string_literal: true

class DescriptionChangeLogger < LoggerBase
  def self.log(image, user)
    return if image.previous_changes[:description].nil?

    old_desc = image.previous_changes[:description].first
    new_desc = image.description

    updater = if user == image.user
      image.author
    else
      user&.name
    end

    s = +"[DESCRIPTION CHANGE: ##{image.id}] #{Booru::CONFIG.settings[:public_url_root]}/#{image.id} by #{updater}"
    s += " - New description: #{sanitize_newlines(new_desc)[0...100]}"
    s += " - Old description: #{sanitize_newlines(old_desc)[0...100]}"

    livefeed_send(s)
  end
end
