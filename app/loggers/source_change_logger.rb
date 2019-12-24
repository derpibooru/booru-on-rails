# frozen_string_literal: true

class SourceChangeLogger < LoggerBase
  def self.log(image, user, old_source)
    updater = if user == image.user
      image.author
    else
      user&.name || I18n.t('booru.anonymous_user')
    end

    s = +"[SOURCE CHANGE: ##{image.id}] #{Booru::CONFIG.settings[:public_url_root]}/#{image.id} by #{updater}"
    s += " - New source: #{image.source_url} - Old source: #{old_source}"

    livefeed_send(s)
  end
end
