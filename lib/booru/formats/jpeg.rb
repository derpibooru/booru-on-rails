# frozen_string_literal: true

require 'tempfile'

module Booru
  module Formats
    # Functions for manipulating JPEG images.
    class Jpeg
      # Construct a new JPEG processor based on the provided image file.
      # @param file [File] the image file
      def initialize(file)
        @file = file
      end

      # Get the actual file this class is attached to.
      # @return [File] the underlying file
      attr_reader :file

      # Always 'jpg'.
      #
      # @return [String]
      def extension
        'jpg'
      end

      # Always 'image/jpeg'.
      #
      # @return [String]
      def mime_type
        'image/jpeg'
      end

      # Always false. JPEGs are never animated.
      # @return [Boolean]
      def animated?
        false
      end

      # Always 0. JPEGs are never animated.
      # @return [Float] duration in seconds
      def duration
        0.0
      end

      # Get the image dimensions of this JPEG.
      # @return [Array] dimensions as [width, height]
      def dimensions
        @dimensions ||= begin
          output, = Open3.capture2('identify', '-format', "%W %H\n", @file.path)
          width, height = output.split("\n")[0].split(' ')

          [width.to_i, height.to_i]
        end
      end

      # Remove potentially identifying information about this image from
      # its headers. This method also automatically orients the JPEG image.
      #
      # @return [Jpeg] a stripped JPEG
      def strip
        @strip ||= begin
          stripped = Tempfile.new(['stripped', '.jpeg']).tap(&:close)
          Open3.capture2('convert', @file.path, '-auto-orient', '-strip', stripped.path)

          Jpeg.new(stripped)
        end
      end

      # Create a suitable static bitmap which represents this image for
      # analysis purposes. This method does nothing for the JPEG format.
      #
      # @return [Jpeg] a preview image
      def preview
        dup
      end

      # Create an image with the same data as this one, but with an optimized
      # on-disk representation.
      #
      # @return [Jpeg] an optimized JPEG
      def optimize
        @optimize ||= begin
          optimized = Tempfile.new(['optimized', '.jpeg']).tap(&:close)
          Open3.capture2('jpegtran', '-optimize', '-outfile', optimized.path, @file.path)

          Jpeg.new(optimized)
        end
      end

      # Scale this JPEG image to fit within the given box, preserving its
      # aspect ratio.
      #
      # @return [Jpeg] a scaled JPEG
      def scale!(width:, height:)
        scaled = Tempfile.new(['scaled', '.png']).tap(&:close)
        scale_filter = "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease"

        Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-vf', scale_filter, scaled.path)
        Open3.capture2('jpegtran', '-optimize', '-outfile', scaled.path, scaled.path)

        Jpeg.new(scaled)
      end
    end
  end
end
