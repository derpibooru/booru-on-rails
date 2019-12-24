# frozen_string_literal: true

class NewImageLogger < LoggerBase
  def self.log(image)
    s = +"[IMAGE: New ##{image.id}]"
    s += " #{Booru::CONFIG.settings[:public_url_root]}/#{image.id} (#{image.image_width}x#{image.image_height} #{image.file_type})"
    s += " - uploader: #{image.author}"
    s += " - source: #{image.source_url}" if image.source_url.present?
    s += " - tags: #{image.tag_list}"

    livefeed_send(s)
  end
end
