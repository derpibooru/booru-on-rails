# frozen_string_literal: true

require 'shellwords'
require 'svg_scrubber'

# Include this module in an uploader class to access image processors that create
# custom CarrierWave versions/alter the original file.
# Example usage:
# run(:pre_process, path_to_image)
module CarrierWave
  module ImageProcessors
    include CarrierWave::MiniMagick

    PROCESSORS = {
      pre_process:    {
        'image/jpeg':    ->(path) do
          # Perform lossy rotation on image if it has EXIF orientation field
          # (web browsers do not respect that, see http://caniuse.com/#search=image-orientation)
          image = ::MiniMagick::Image.open(path)
          orientation = image.exif['Orientation']
          if orientation.to_i > 1 # 1 is the default orientation
            image.auto_orient
            image.strip # remove EXIF metadata to prevent image from being rotated again
            image.write(path)
          end
        end,
        'image/svg+xml': ->(path) do
          SVGScrubber.scrub(path)
        end
      },
      create_version: {
        'image/png':     ->(source, dest, width, height) do
          ::MiniMagick::Tool::Convert.new do |cmd|
            cmd.resize "#{width}x#{height}"
            cmd << source
            cmd << dest
          end
          `nice -n 19 optipng -quiet -fix -i0 -o2 #{dest.shellescape}`
        end,
        'image/jpeg':    ->(source, dest, width, height) do
          ::MiniMagick::Tool::Convert.new do |cmd|
            cmd.resize "#{width}x#{height}"
            cmd << source
            cmd << dest
          end
          `nice -n 19 jpegtran -optimize -outfile #{dest.shellescape} #{dest.shellescape}`
        end,
        'image/gif':     ->(source, dest, width, height) do
          palette = Tempfile.new(['palette', '.png']).tap(&:close)
          filters = "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease"
          `#{Booru::CONFIG.settings[:ffmpeg_binary]} -loglevel 0 -i #{source.shellescape} -vf "#{filters},palettegen=stats_mode=diff" -y #{palette.path}`
          `#{Booru::CONFIG.settings[:ffmpeg_binary]} -loglevel 0 -i #{source.shellescape} -i #{palette.path} -lavfi "#{filters} [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -y #{dest.shellescape}`
        end,
        'image/svg+xml': ->(source, dest, width, height) do
          # source is a png render (converting the original file is slower than resizing a rasterized version)
          png = ::MiniMagick::Image.open(source)
          png.resize("#{width}x#{height}")
          png.write(dest)
        end,
        'video/webm':    ->(source, dest, width, height, permissions) do
          if width && height
            width &= 4_294_967_294
            height &= 4_294_967_294
            `#{Booru::CONFIG.settings[:ffmpeg_binary]} -loglevel 0 -threads 0 -y -i #{source.shellescape} -c:v libvpx -b:v 1M -crf 10 -speed 16 -vf "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease" #{dest.shellescape}`
            `#{Booru::CONFIG.settings[:ffmpeg_binary]} -loglevel 0 -threads 0 -y -i #{source.shellescape} -vf "scale=w=#{width}:h=#{height}:force_original_aspect_ratio=decrease, scale=trunc(iw/2)*2:trunc(ih/2)*2" -preset veryfast #{dest.gsub(/webm\z/, 'mp4').shellescape}`
          else
            FileUtils.cp(source, dest)
            `#{Booru::CONFIG.settings[:ffmpeg_binary]} -loglevel 0 -threads 0 -y -i #{source.shellescape} -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -preset veryfast #{dest.gsub(/webm\z/, 'mp4').shellescape}`
          end
          File.chmod(permissions, dest.gsub(/webm\z/, 'mp4')) rescue nil
        end
      },
      post_process:   {
        'image/png':  ->(path) do
          `nice -n 19 optipng -quiet -fix -i0 -o2 #{path.shellescape}`
        end,
        'image/jpeg': ->(path) do
          `nice -n 19 jpegtran -optimize -outfile #{path.shellescape} #{path.shellescape}`
        end,
        'image/gif':  ->(path) do
          `nice -n 19 gifsicle --careful -O2 "#{path.shellescape}" -o "#{path.shellescape}"`
        end
      },
      other_process:  {
        'video/webm': ->(orig_path, destdir) do
          duration = `ffprobe -loglevel quiet -of 'compact=nokey=1:print_section=0' -show_format_entry duration #{orig_path.shellescape}`.chomp.to_f / 10
          ffmpeg_binary = Booru::CONFIG.settings[:ffmpeg_binary]
          [[250, :thumb], [150, :thumb_small], [50, :thumb_tiny]].each do |w, n|
            `#{ffmpeg_binary} -loglevel 0 -i #{orig_path.shellescape} -vf "fps=1/#{duration},scale=w=#{w}:h=#{w}:force_original_aspect_ratio=decrease" -vframes 10 -qscale:v 2 -f image2pipe -vcodec ppm - | convert -delay 50 -loop 0 - gif:- | gifsicle -O2 > #{destdir}/#{n}.gif`
          end
        end
      }
    }.freeze

    def run(processor, *args)
      processor = PROCESSORS[processor][content_type.to_sym] || PROCESSORS[processor][:default]
      processor&.call(*args)
    end
  end
end
