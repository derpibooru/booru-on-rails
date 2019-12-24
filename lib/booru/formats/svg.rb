# frozen_string_literal: true

require 'tempfile'

module Booru
  module Formats
    # Functions for manipulating SVG images.
    class Svg
      # Construct a new SVG processor based on the provided image file.
      # @param file [File] the image file
      def initialize(file)
        @file = file
      end

      # Get the actual file this class is attached to.
      # @return [File] the underlying file
      attr_reader :file

      # Always 'svg'.
      #
      # @return [String]
      def extension
        'svg'
      end

      # Always 'image/svg+xml'.
      #
      # @return [String]
      def mime_type
        'image/svg+xml'
      end

      # Always false. No SMIL support.
      # @return [Boolean]
      def animated?
        false
      end

      # Always 0. No SMIL support.
      # @return [Float] duration in seconds
      def duration
        0.0
      end

      # Get the page dimensions of this SVG.
      # @return [Array] dimensions as [width, height]
      def dimensions
        @dimensions ||= begin
          output, = Open3.capture2('identify', '-format', "%W %H\n", "msvg:#{@file.path}")
          width, height = output.split("\n")[0].split(' ')

          [width.to_i, height.to_i]
        end
      end

      # Remove potentially identifying information about this SVG file.
      # Also removes references to linked files, which could pose a security
      # hazard.
      #
      # @return [Svg] a stripped SVG
      # @see SVGScrubber
      def strip
        @strip ||= begin
          stripped = Tempfile.new(['stripped', '.svg']).tap(&:close)
          FileUtils.cp(@file.path, stripped.path)
          SVGScrubber.scrub(stripped.path)

          Svg.new(stripped)
        end
      end

      # Create a suitable static bitmap which represents this image for
      # analysis purposes.
      #
      # @return [Png] a preview image
      def preview
        @preview ||= begin
          preview = Tempfile.new(['preview', '.png']).tap(&:close)
          Open3.capture2('inkscape', @file.path, '--export-png', preview.path)

          Png.new(preview)
        end
      end

      # Create an image with the same data as this one, but with an optimized
      # on-disk representation. This does nothing for SVG.
      #
      # @return [Svg] an optimized SVG
      def optimize
        dup
      end

      # Scale a rendering of this image to fit within the given box, preserving
      # its aspect ratio.
      #
      # @return [Png] a scaled PNG
      def scale!(width:, height:)
        scaled = Tempfile.new(['scaled', '.png']).tap(&:close)
        scale_filter = "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease"

        Open3.capture2e('ffmpeg', '-y', '-i', preview.file.path, '-vf', scale_filter, scaled.path)
        Open3.capture2('jpegtran', '-optimize', '-outfile', scaled.path, scaled.path)

        Png.new(scaled)
      end
    end
  end
end
