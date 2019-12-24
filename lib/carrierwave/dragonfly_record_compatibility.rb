# frozen_string_literal: true

# A module that sets model[mounted_as] (uploaded file name) à la Dragonfly
# and overrides CarrierWave URI generation to handle the format.
# Dragonfly:
#   image_uid | 2016/01/01/filename.png
# CarrierWave:
#   image | filename.png
# This is meant as a temporary extension. When migrating the data, do note that
# the date part (2016/01/01) does not always match model creation date — that
# needs to be accounted for to avoid losing those special snowflakes.
module CarrierWave
  module DragonflyRecordCompatibility
    # Override this method to specify server root prepended to relative paths.
    def url_root
      Booru::CONFIG.settings[:media_url_root]
    end

    def url
      dragonfly_path = model[mounted_as]
      "#{url_root}/#{dragonfly_path}"
    end

    def dirty_preview_url
      # By default, CarrierWave returns a relative URL to "uploads/tmp/{upload}" for pending uploads
      "data:#{file.content_type};base64,#{Base64.encode64(file.read)}" rescue nil
    end

    def filename
      if file_changed?
        dirty_filename
      else
        model[mounted_as]
      end
    end

    def file_changed?
      !@dirty_filename_saved && dirty_filename != model[mounted_as]
    end

    def dirty_filename
      return model[mounted_as] unless file

      if file.path.include?(store_dir)
        file.path.split(store_dir).last.sub(/\A\//, '')
      else
        time = model[:created_at].present? ? model.created_at : Time.zone.now
        dragonfly_extension = "#{time.year}/#{time.month}/#{time.day}"
        filename = "#{time.usec}#{Digest::SHA256.hexdigest(file.path)[0..16]}.#{file.extension}"
        filename = "#{dragonfly_extension}/#{filename}"
        force_dirty_if_persisted! filename
        filename
      end
    end

    def force_dirty_if_persisted!(dirty)
      if model.persisted? && model[mounted_as] != dirty
        model.update_column mounted_as, dirty
        @dirty_filename_saved = true
      end
    end
  end
end
