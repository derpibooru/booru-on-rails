# frozen_string_literal: true

require 'tempfile'

module Booru
  module Formats
    # Functions for manipulating WebM videos.
    class Webm
      # Construct a new WebM processor based on the provided video file.
      # @param file [File] the video file
      def initialize(file)
        @file = file
      end

      # Get the actual file this class is attached to.
      # @return [File] the underlying file
      attr_reader :file

      # Always 'webm'.
      #
      # @return [String]
      def extension
        'webm'
      end

      # Always 'video/webm'.
      #
      # @return [String]
      def mime_type
        'video/webm'
      end

      # Always true.
      # @return [Boolean]
      def animated?
        true
      end

      # Get the duration of this WebM.
      # @return [Float] duration in seconds
      def duration
        @duration ||= begin
          output, = Open3.capture2('ffprobe', '-i', @file.path, '-show_entries', 'format=duration', '-v', 'quiet', '-of', 'csv=p=0')
          output.to_f
        end
      end

      # Get the dimensions of this WebM.
      # @return [Array] dimensions as [width, height]
      def dimensions
        @dimensions ||= begin
          output, = Open3.capture2('ffprobe', '-i', @file.path, '-show_entries', 'stream=width,height', '-v', 'quiet', '-of', 'csv=p=0')
          width, height = output.split(',')[0..1]

          [width.to_i, height.to_i]
        end
      end

      # Remove potentially identifying information about this video
      # from its headers. This method does nothing for the WebM format.
      #
      # @return [Webm] a stripped WebM
      def strip
        dup
      end

      # Create a suitable static bitmap which represents this video for
      # analysis purposes.
      #
      # @return [Png] a preview image
      def preview
        @preview ||= begin
          preview = Tempfile.new(['rendered', '.png']).tap(&:close)

          Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-ss', (duration / 2).to_s, '-frames:v', '1', preview.path)

          Png.new(preview)
        end
      end

      # Create a video with the same data as this one, but with an optimized
      # on-disk representation. This does nothing for WebM.
      #
      # @return [Webm] an optimized WebM
      def optimize
        dup
      end

      # Scale a rendering of this video to fit within the given box, preserving
      # its aspect ratio.
      #
      # @return [Webm] a scaled WebM
      def scale!(width:, height:)
        width, height = normalize_dimensions(width, height)
        scaled = Tempfile.new(['scaled', '.webm']).tap(&:close)
        scale_filter = "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease"

        Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-c:v', 'libvpx', '-crf', '10', '-b:v', '5M', '-vf', scale_filter, scaled.path)

        Webm.new(scaled)
      end

      # Same as {#scale!}, but returns an MP4 instead.
      #
      # @return [Mp4] a scaled MP4
      def scale_mp4!(width:, height:)
        width, height = normalize_dimensions(width, height)
        scaled = Tempfile.new(['scaled', '.mp4']).tap(&:close)
        scale_filter = "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease"

        Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-c:v', 'libx264', '-crf', '18', '-vf', scale_filter, scaled.path)

        Mp4.new(scaled)
      end

      # Same as {#scale!}, but returns a GIF instead.
      #
      # @return [Gif] a scaled GIF
      def scale_gif!(width:, height:)
        palette = Tempfile.new(['palette', '.png']).tap(&:close)
        scaled  = Tempfile.new(['scaled', '.gif']).tap(&:close)

        scale_filter   = "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease"
        palette_filter = 'paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle'
        filter_graph   = "#{scale_filter} [x]; [x][1:v] #{palette_filter}"

        Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-vf', 'palettegen=stats_mode=diff', palette.path)
        Open3.capture2e('ffmpeg', '-y', '-i', @file.path, '-i', palette.path, '-lavfi', filter_graph, scaled.path)

        Gif.new(scaled)
      end

      private

      # Force dimensions to be a multiple of 2. This is required by the
      # libvpx and x264 encoders.
      #
      # @param width [Integer] input width
      # @param height [Integer] input height
      # @return [Array] output dimensions in [width, height]
      def normalize_dimensions(width, height)
        [width & ~1, height & ~1]
      end
    end
  end
end
