# frozen_string_literal: true

require 'English'
require 'shellwords'

# Include this module in an uploader class to access image analyzers for properties
# that get incorrectly recognized by ImageMagick.
# Example usage:
# width, height = analyze(:dimensions, image)
module CarrierWave
  module ImageAnalyzers
    include CarrierWave::MiniMagick

    ANALYZERS = {
      dimensions: {
        'default':       ->(image) do
          image.dimensions
        end,
        'image/gif':     ->(image) do
          [image['%W'].to_i, image['%H'].to_i] # using page geometry because the size may differ from frame to frame
        end,
        'image/svg+xml': ->(image) do
          msvg = ::MiniMagick::Tool::Identify.new do |cmd|
            cmd.format '%w %h'
            cmd << "msvg:#{image.path.shellescape}"
          end
          msvg.split(' ').map!(&:to_i)
        end,
        'video/webm':    ->(file) do
          output = `ffprobe -v error -show_entries stream=width,height -of default=noprint_wrappers=1 #{file.shellescape}`
          raise ArgumentError, "couldn't read video" if $CHILD_STATUS != 0

          output.split("\n").map { |x| x.gsub(/.*?(?=\d+)/, '').to_i }
        end
      },
      length:     {
        'video/webm': ->(file) do
          output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{file.shellescape}`
          raise ArgumentError, "couldn't read video" if $CHILD_STATUS != 0

          output.to_f
        end
      }
    }.freeze

    def analyze(analyzer, *args, mime_type: content_type)
      ANALYZERS[analyzer][mime_type.to_sym]&.call(*args) || ANALYZERS[analyzer][:default].call(*args)
    end
  end
end
