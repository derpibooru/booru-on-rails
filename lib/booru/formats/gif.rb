# frozen_string_literal: true

require 'tempfile'

module Booru
  module Formats
    # Functions for manipulating static and animated GIF images.
    class Gif
      # Construct a new GIF processor based on the provided image file.
      # @param file [File] the image file
      def initialize(file)
        @file = file
      end

      # Get the actual file this class is attached to.
      # @return [File] the underlying file
      attr_reader :file

      # Always 'gif'.
      #
      # @return [String]
      def extension
        'gif'
      end

      # Always 'image/gif'.
      #
      # @return [String]
      def mime_type
        'image/gif'
      end

      # Determine whether this GIF is animated. GIF images with more than one
      # frame are considered to be animated, regardless of frame timing.
      #
      # @return [Boolean]
      def animated?
        @animated ||= begin
          output, = Open3.capture2('identify', @file.path)
          output.split("\n").size > 1
        end
      end

      # Get the duration of this GIF, if it is animated. Otherwise, returns 0.
      #
      # @return [Float] duration in seconds
      def duration
        return 0.0 unless animated?

        @duration ||= begin
          output, = Open3.capture2('ffprobe', '-i', @file.path, '-show_entries', 'format=duration', '-v', 'quiet', '-of', 'csv=p=0')
          output.to_f
        end
      end

      # Get the page geometry of this GIF. Note that the first frame of a
      # GIF is not required to have the same dimensions as the page;
      # however, a frame may not render larger than the page.
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
      # its headers. This method does nothing for the GIF format.
      #
      # @return [Gif] a stripped GIF
      def strip
        dup
      end

      # Create a suitable static bitmap which represents this image for
      # analysis purposes.
      #
      # @return [Png] a PNG preview
      def preview
        @preview ||= begin
          preview = Tempfile.new(['rendered', '.png']).tap(&:close)

          Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-ss', (duration / 2).to_s, '-frames:v', '1', preview.path)

          Png.new(preview)
        end
      end

      # Create an image with the same data as this one, but with an optimized
      # on-disk representation.
      #
      # @return [Gif] an optimized GIF
      def optimize
        @optimize ||= begin
          optimized = Tempfile.new(['optimized', '.gif']).tap(&:close)

          Open3.capture2('gifsicle', '--careful', '-O2', @file.path, '-o', optimized.path)

          Gif.new(optimized)
        end
      end

      # Scale this GIF image to fit within the given box, preserving its
      # aspect ratio.
      #
      # @return [Gif] a scaled GIF
      def scale!(width:, height:)
        palette = Tempfile.new(['palette', '.png']).tap(&:close)
        scaled  = Tempfile.new(['scaled', '.gif']).tap(&:close)

        scale_filter   = "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease"
        palette_filter = 'paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle'
        filter_graph   = "#{scale_filter} [x]; [x][1:v] #{palette_filter}"

        Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-vf', 'palettegen=stats_mode=diff', palette.path)
        Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-i', palette.path, '-lavfi', filter_graph, scaled.path)

        Gif.new(scaled)
      end
    end
  end
end
