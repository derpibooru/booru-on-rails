# frozen_string_literal: true

require 'tempfile'

module Booru
  module Formats
    # Functions for manipulating MP4 videos.
    class Mp4
      # Construct a new MP4 processor based on the provided video file.
      # @param file [File] the video file
      def initialize(file)
        @file = file
      end

      # Get the actual file this class is attached to.
      # @return [File] the underlying file
      attr_reader :file

      # Always 'mp4'.
      #
      # @return [String]
      def extension
        'mp4'
      end

      # Always 'video/mp4'.
      #
      # @return [String]
      def mime_type
        'video/mp4'
      end

      # Always true.
      # @return [Boolean]
      def animated?
        true
      end

      # Get the duration of this MP4.
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
    end
  end
end
