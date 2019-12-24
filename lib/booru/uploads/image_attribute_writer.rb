# frozen_string_literal: true

require 'digest'

module Booru
  module Uploads
    class ImageAttributeWriter
      # Create a new ImageAttributeWriter instance.
      #
      # Supported option keys:
      #   * +:animated+ - write animated status to the given column
      #   * +:duration+ - write duration to the given column
      #   * +:width+ - write image width to the given column
      #   * +:height+ - write image height to the given column
      #   * +:aspect+ - write image aspect ratio to the given column
      #   * +:size+ - write image size to the given column
      #   * +:mime+ - write image MIME type to the given column
      #   * +:ext+ - write proper file extension (no dot) to the given column
      #   * +:name+ - write filename to the given column
      #   * +:sha512+ - write file sha512 to the given column
      #   * +:oname+ - write filename to the given column, if not present
      #   * +:osha512+ - write file sha512 to the given column, if not present
      #
      # @param options [Hash] a collection of attributes to write
      #
      def initialize(name, options)
        @name = name
        @options = options
      end

      # Write any requested attributes of the attached image for this model.
      #
      # @param model [ApplicationRecord] a model instance
      # @param format [Object] a format class, such as {Formats::Png}
      #
      def write!(model:, format:)
        write_animated(model, format)
        write_duration(model, format)
        write_width(model, format)
        write_height(model, format)
        write_aspect(model, format)
        write_size(model, format)
        write_mime(model, format)
        write_ext(model, format)
        write_name(model, format)
        write_sha512(model, format)
        write_oname(model, format)
        write_osha512(model, format)
      end

      private

      attr_reader :name
      attr_reader :options

      def write_animated(model, format)
        model[options[:animated]] = format.animated? if options[:animated]
      end

      def write_duration(model, format)
        model[options[:duration]] = format.duration if options[:duration]
      end

      def write_width(model, format)
        model[options[:width]] = format.dimensions[0] if options[:width]
      end

      def write_height(model, format)
        model[options[:height]] = format.dimensions[1] if options[:height]
      end

      def write_aspect(model, format)
        model[options[:aspect]] = format.dimensions[0].to_f / format.dimensions[1] if options[:aspect]
      end

      def write_size(model, format)
        model[options[:size]] = format.file.size if options[:size]
      end

      def write_mime(model, format)
        model[options[:mime]] = format.mime_type if options[:mime]
      end

      def write_ext(model, format)
        model[options[:ext]] = format.extension if options[:ext]
      end

      def write_name(model, format)
        model[options[:name]] = File.basename(format.file.name) if options[:name]
      end

      def write_sha512(model, format)
        model[options[:sha512]] = Digest::SHA512.hexdigest(format.file.read) if options[:sha512]
      end

      def write_oname(model, format)
        model[options[:oname]] ||= File.basename(format.file.name) if options[:oname]
      end

      def write_osha512(model, format)
        model[options[:osha512]] ||= Digest::SHA512.hexdigest(format.file.read) if options[:osha512]
      end
    end
  end
end
