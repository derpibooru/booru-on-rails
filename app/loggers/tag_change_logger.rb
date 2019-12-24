# frozen_string_literal: true

class TagChangeLogger < LoggerBase
  def self.log(image, user, tags_added, tags_removed)
    details = []
    details << "Added tags: #{tags_added.map(&:name).join(', ')}" if tags_added.any?
    details << "Removed tags: #{tags_removed.map(&:name).join(', ')}" if tags_removed.any?

    updater = if user == image.user
      image.author
    else
      user&.name || I18n.t('booru.anonymous_user')
    end

    s = +"[TAG CHANGE: ##{image.id}] #{Booru::CONFIG.settings[:public_url_root]}/#{image.id} by #{updater} - "
    s += details.join(' | ')

    livefeed_send(s)
  end
end
