# frozen_string_literal: true

module Booru
  module Uploads
    # MIME type utilities.
    class Mime
      # Mapping of common MIME types to format handlers.
      FORMAT_HANDLERS = {
        'audio/webm'    => Formats::Webm,
        'image/gif'     => Formats::Gif,
        'image/jpeg'    => Formats::Jpeg,
        'image/png'     => Formats::Png,
        'image/svg'     => Formats::Svg,
        'image/svg+xml' => Formats::Svg,
        'video/mp4'     => Formats::Mp4,
        'video/webm'    => Formats::Webm
      }.freeze

      # Determine the MIME type of the given filename.
      #
      # @param filename [String]
      # @return [String] the MIME type
      def self.file_mime(filename)
        magic.file(filename)
      end

      # Determine the MIME type of the file represented by the contents of
      # the given string.
      #
      # @param buffer [String]
      # @return [String] the MIME type
      def self.buffer_mime(buffer)
        magic.buffer(buffer)
      end

      # Create an attachment format handler for the given filename.
      #
      # @param filename [String]
      # @return [Class] one of [Webm Gif Jpeg Png Svg Mp4]
      # @raise [KeyError] provided MIME type is not known
      def self.format_for(filename)
        mime   = file_mime(filename)
        format = FORMAT_HANDLERS.fetch(mime)
        file   = File.open(filename)

        format.new(file)
      end

      # Direct access to libmagic. This can be used if any additional
      # processing not covered by the usecases given here is required.
      #
      # @return [Magic]
      def self.magic
        @magic ||= Magic.new(Magic::MIME_TYPE)
      end
    end
  end
end
