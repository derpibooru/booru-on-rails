# frozen_string_literal: true

require 'tempfile'

module Booru
  module Formats
    # Functions for manipulating static (PNG) and animated (APNG) images.
    # MNG is not supported.
    class Png
      # Construct a new PNG processor based on the provided image file.
      #
      # @param file [File] the image file
      def initialize(file)
        @file = file
      end

      # Get the actual file this class is attached to.
      # @return [File] the underlying file
      attr_reader :file

      # Always 'png'.
      #
      # @return [String]
      def extension
        'png'
      end

      # Always 'image/png'.
      #
      # @return [String]
      def mime_type
        'image/png'
      end

      # Determine whether this PNG is animated. PNG images with APNG chunks
      # are always considered to be animated.
      #
      # @return [Boolean]
      def animated?
        @animated ||= begin
          output, = Open3.capture2('ffprobe', '-v', 'quiet', '-show_entries', 'stream=codec_name', '-of', 'csv=p=0', @file.path)
          output.split("\n")[0] == 'apng'
        end
      end

      # Currently always 0. To be fixed when tooling improves.
      # @return [Float] duration in seconds
      def duration
        0.0
      end

      # Get the image dimensions of this PNG.
      #
      # @return [Array] dimensions as [width, height]
      def dimensions
        @dimensions ||= begin
          output, = Open3.capture2('identify', '-format', "%W %H\n", @file.path)
          width, height = output.split("\n")[0].split(' ')

          [width.to_i, height.to_i]
        end
      end

      # Remove potentially identifying information about this image from
      # its headers. This method does nothing for the PNG format.
      #
      # @return [Png] a stripped PNG
      def strip
        dup
      end

      # Create a suitable static bitmap which represents this image for
      # analysis purposes. This method does nothing for the PNG format.
      #
      # @return [Png] a preview image
      def preview
        dup
      end

      # Create an image with the same data as this one, but with an optimized
      # on-disk representation.
      #
      # @return [Png] an optimized PNG
      def optimize
        @optimize ||= begin
          optimized = Tempfile.new(['optimized', '.png']).tap(&:close)

          Open3.capture2e('optipng', '-fix', '-i0', '-o2', @file.path, '-out', optimized.path)

          Png.new(optimized)
        end
      end

      # Scale this PNG image to fit within the given box, preserving its
      # aspect ratio.
      #
      # @return [Png] a scaled PNG
      def scale!(width:, height:)
        scaled = Tempfile.new(['scaled', '.png']).tap(&:close)
        scale_filter = "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease"

        Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-vf', scale_filter, scaled.path)
        Open3.capture2e('optipng', '-i0', '-o1', scaled.path)

        Png.new(scaled)
      end
    end
  end
end
