# frozen_string_literal: true

require_relative 'image_analyzers'
require 'carrierwave/remote_file'

module CarrierWave
  module ImageValidations
    include CarrierWave::MiniMagick
    include CarrierWave::ImageAnalyzers

    def self.included(base)
      base.class_eval do
        before :cache, :validate!
      end
    end

    # Override this method to provide a file size limitation, e.g. (0..100.kilobytes)
    # TODO: https://github.com/carrierwaveuploader/carrierwave/blob/master/lib/carrierwave/uploader/file_size.rb
    # (The problem with CarrierWave's method is that it doesn't pretty print the size, showing byte range instead)
    def allowed_file_size
    end

    # Override this method to provide an image width limitation, e.g. (0..1000)
    def allowed_width
    end

    # Override this method to provide an image height limitation, e.g. (0..1000)
    def allowed_height
    end

    def validate!(file)
      if file.content_type == 'video/webm'
        image_size = File.stat(file.path)
        validate_file_size!(image_size) if allowed_file_size&.is_a?(Range)

        width, height = analyze(:dimensions, file.path, mime_type: file.content_type)
      else
        image = ::MiniMagick::Image.open(file.path)
        validate_file_size!(image) if allowed_file_size&.is_a?(Range)

        width, height = analyze(:dimensions, image, mime_type: file.content_type)
      end

      validate_dimension!('width', width) if allowed_width&.is_a?(Range)
      validate_dimension!('height', height) if allowed_height&.is_a?(Range)
    end

    private

    def validate_file_size!(image)
      real = image.size
      allowed = allowed_file_size
      error I18n.t('errors.messages.min_file_size_error', limit: pretty_size(allowed.min)) if real < allowed.min
      error I18n.t('errors.messages.max_file_size_error', limit: pretty_size(allowed.max)) if real > allowed.max
    end

    def validate_dimension!(dimension, real)
      allowed = send("allowed_#{dimension}")
      error I18n.t("errors.messages.min_image_#{dimension}_error", limit: pretty_dimen(allowed.min)) if real < allowed.min
      error I18n.t("errors.messages.max_image_#{dimension}_error", limit: pretty_dimen(allowed.max)) if real > allowed.max
    end

    def error(message)
      raise CarrierWave::IntegrityError, message
    end

    def pretty_size(bytes)
      "#{bytes / 1024}kB"
    end

    def pretty_dimen(dimension)
      "#{dimension}px"
    end
  end
end
