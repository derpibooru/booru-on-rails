# frozen_string_literal: true

class ImageRepairer
  def initialize(image)
    @image = image
  end

  def repair!
    if image_readable?
      @image.update_columns(processed: false, thumbnails_generated: false)
      ProcessImageJob.perform_later(@image.id)
      true
    else
      remove_image!
      false
    end
  end

  def image_readable?
    !@image.destroyed_content && @image.image.readable?
  end

  def remove_image!
    Rails.logger.error "Image unreadable at #{(@image.image.file.path rescue 'nil')}, hiding it and wiping deduplication metadata"
    @image.update_columns image: nil, image_sha512_hash: nil, image_orig_sha512_hash: nil,
                          nw_intensity: nil, ne_intensity: nil, sw_intensity: nil, se_intensity: nil, average_intensity: nil
    ImageHider.new(@image, reason: 'Autoremoved - file corrupt/unreadable, please reupload.').save
    HidableLogger.log(@image, 'Deleted', 'System', 'Autoremoved - file corrupt/unreadable, please reupload.')
  end
end
