# frozen_string_literal: true

module Booru
  module Uploads
    class ImageValidator
      # Create a new ImageValidator instance.
      #
      # Supported option keys:
      #   * +:width+ - validate inclusion of width in a Range
      #   * +:height+ - validate inclusion of height in a Range
      #   * +:size+ - validate inclusion of byte size in a Range
      #   * +:mime+ - validate inclusion of MIME type in a Range
      #
      # @param options [Hash] any supported validations
      #
      def initialize(name, options)
        @name = name
        @options = options
      end

      # Validate the attached image for this model. Places errors on
      # the model if it is invalid.
      #
      # @param model [ApplicationRecord] a model instance
      # @param format [Object] a format class such as {Formats::Png}
      #
      def validate!(model:, format:)
        validate_width(model, format)
        validate_height(model, format)
        validate_size(model, format)
        validate_mime(model, format)
      end

      private

      attr_reader :name
      attr_reader :options

      def validate_width(model, format)
        return if !options[:width] || options[:width].include?(format.dimensions[0])

        model.errors.add(name, "width must be between #{options[:width].begin} and #{options[:width].end}")
      end

      def validate_height(model, format)
        return if !options[:height] || options[:height].include?(format.dimensions[1])

        model.errors.add(name, "height must be between #{options[:height].begin} and #{options[:height].end}")
      end

      def validate_size(model, format)
        return if !options[:size] || options[:size].include?(format.file.size)

        model.errors.add(name, "size must be between #{options[:size].begin} and #{options[:size].end}")
      end

      def validate_mime(model, format)
        return if !options[:mime] || options[:mime].include?(format.mime_type)

        model.errors.add(name, "content type must be one of #{options[:mime].join(', ')}")
      end
    end
  end
end
