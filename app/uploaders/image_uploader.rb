# frozen_string_literal: true

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::ImageValidations
  include CarrierWave::ImageAnalyzers
  include CarrierWave::ImageProcessors
  include CarrierWave::DragonflyRecordCompatibility

  storage :file

  VERSIONS = {
    thumb_tiny:  [50, 50],
    thumb_small: [150, 150],
    thumb:       [250, 250],
    small:       [320, 240],
    medium:      [800, 600],
    large:       [1280, 1024],
    tall:        [1024, 4096],
    full:        nil
  }.freeze

  EXTENSION_WHITELIST = %w[png jpg jpeg gif svg webm].freeze
  def extension_whitelist
    EXTENSION_WHITELIST
  end

  CONTENT_TYPE_WHITELIST = %w[image/png image/jpeg image/gif image/svg\+xml video/webm].freeze
  def content_type_whitelist
    CONTENT_TYPE_WHITELIST
  end

  FORMATS_FOR_CONTENT_TYPE = {
    'image/png'     => 'png',
    'image/jpeg'    => 'jpeg',
    'image/gif'     => 'gif',
    'image/svg+xml' => 'svg',
    'video/webm'    => 'webm'
  }.freeze

  EXTRA_FORMATS = %w[webm mp4].freeze

  def allowed_file_size
    0..25.megabytes
  end

  process :set_metadata
  # Processing is executed only once, right after the file has been cached, which leads to any
  # non-persistent attributes getting lost on image form resubmission. Therefore we run processing again
  # on every retrieval from cache — it only happens when the image is not stored yet.
  after :retrieve_from_cache, :process!

  # CarrierWave overrides ActiveRecord's dirty tracking on the mounter column
  def previously_changed?
    model.previous_changes[:image_sha512_hash] && model.image_sha512_hash.present?
  end

  # what the fuck
  def content_type
    ct = super
    ct == 'audio/webm' ? 'video/webm' : ct
  end

  def process_after_creation!
    FileUtils.rm_rf  version_dir(hidden: model.hidden_from_users?)
    FileUtils.mkpath version_dir(hidden: model.hidden_from_users?)

    pre_process!
    set_intensities

    create_image_versions
    generate_webm if should_generate_webm?
    model.update_columns thumbnails_generated: true, updated_at: Time.zone.now

    post_process!
    model.update_columns image_size: file.size, processed: true, updated_at: Time.zone.now
  end

  # Do not keep images in cache, it may be expensive for large files.
  def move_to_store
    true
  end

  def created_at_path
    "#{model.created_at.year}/#{model.created_at.month}/#{model.created_at.day}"
  end

  def store_dir
    'system/images'
  end

  def version_dir(hidden: false)
    "#{root}/system/images/thumbs/#{version_dir_rel(hidden: hidden)}"
  end

  def version_dir_rel(hidden: false)
    "#{created_at_path}/#{hidden ? "#{model.id}-#{model.hidden_image_key}" : model.id}"
  end

  # Overrides CarrierWave's method to provide URIs for a particular custom-generated version.
  # You can pass a definite version (:thumb, :medium) or a dimension
  # array [width, height] to find a suitable one as a value of +version+.
  def url(version = nil, hidden: false)
    return super() if version.nil?

    version = version_by_size(version[0], version[1]) if version.is_a?(Array)
    "#{Booru::CONFIG.settings[:image_url_root]}/#{version_path(version, hidden: hidden, relative: true)}"
  end

  def view_urls(hidden: false)
    if hidden
      view_urls_nocache(hidden: true)
    else
      @view_urls ||= view_urls_nocache(hidden: false)
    end
  end

  # Allocation-minimized version.
  def view_urls_nocache(hidden: false)
    base_path = "#{Booru::CONFIG.settings[:image_url_root]}/#{model.created_at.year}/#{model.created_at.month}/#{model.created_at.day}/#{hidden ? "#{model.id}-#{model.hidden_image_key}" : model.id}"
    file_ext = model.image_format&.downcase || ''
    file_ext = 'png' if file_ext == 'svg'
    urls = {}

    VERSIONS.each do |version, _|
      urls[version] = "#{base_path}/#{version}.#{file_ext}"
    end

    urls[:full] = "#{Booru::CONFIG.settings[:image_url_root]}/view/#{model.created_at.year}/#{model.created_at.month}/#{model.created_at.day}/#{model.id}.#{file_ext}" if !hidden

    if model.is_animated? && model.processed?
      urls[:webm] = "#{base_path}/full.webm"
      urls[:mp4] = "#{base_path}/full.mp4"
    end

    urls
  end

  # Returns a link to the image with filename containing all the tags.
  # Make sure the server has the proper rewrite rules to handle these.
  def pretty_url(short: false, download: false)
    root = "#{Booru::CONFIG.settings[:image_url_root]}/#{download ? 'download' : 'view'}/#{created_at_path}"
    filename = short ? model.id.to_s : model.file_name
    ext = model.image_format.to_s.downcase
    ext = 'png' if model.image_mime_type == 'image/svg+xml' && !download
    "#{root}/#{filename}.#{ext}"
  end

  def version_path(version, hidden: false, relative: false)
    file_ext = version_file_ext
    if EXTRA_FORMATS.include? version
      file_ext = version
      version = :full
    end
    "#{relative ? version_dir_rel(hidden: hidden) : version_dir(hidden: hidden)}/#{version}.#{file_ext}"
  end

  # Verifies that images are in the right place on disk — if they're hidden, they shouldn't be in a publicly accessible place (and vice versa)
  def move_hidden_versions!
    # The current and past paths are determined by hide state.
    curr_loc = version_dir(hidden: model.hidden_from_users?)
    past_loc = version_dir(hidden: !model.hidden_from_users?)
    if File.exist? past_loc
      FileUtils.rm_rf(curr_loc, secure: true) if File.exist? curr_loc
      FileUtils.mv(past_loc, curr_loc)
    end
  end

  # Destroys all image file data. This is imperative in extreme cases of +Image+
  # records that require  destruction of incriminating content; see
  # +DestroyableContent+.
  def nuke_image_files!
    [version_dir(hidden: true), version_dir(hidden: false)].each do |dir|
      FileUtils.rm_rf(dir, secure: true) if File.exist?(dir)
    end
    # Ban related URIs from the cache. This would be done already in the controller workflow
    # of deleting the image then destroying contents, but let's do it again here for insurance.
    model.remove_image!
    remove!
  end

  def readable?
    (file.exists? && (model.image_mime_type == 'video/webm' || MiniMagick::Image.open(file.file))) rescue false
  end

  private

  def version_file_ext
    file_ext = model.image_format.to_s.downcase
    file_ext = 'png' if model.image_mime_type == 'image/svg+xml' # for svg, thumb paths are always png
    file_ext
  end

  def version_by_size(width, height)
    width = width.to_i
    height = height.to_i
    iwidth = model.image_width.to_i
    iheight = model.image_height.to_i
    return :tall if width > 1024 && iheight > 1024 && (iheight > (iwidth * 2.5))

    VERSIONS.each_pair do |type, dimensions|
      next unless dimensions

      dwidth = iwidth < dimensions[0] ? iwidth : dimensions[0]
      dheight = iheight < dimensions[1] ? iheight : dimensions[1]
      return type if dwidth > width || dheight > height
    end
    :full
  end

  def should_generate_webm?
    model.is_animated? && $flipper[:webm_generation].enabled? && !webm_generated?
  end

  def webm_generated?
    File.exist?("#{version_dir(hidden: model.hidden_from_users?)}/full.webm") &&
      File.exist?("#{version_dir(hidden: model.hidden_from_users?)}/full.mp4")
  end

  def set_metadata
    model.image_name ||= file.filename
    # content_type isn't reliable enough with JPEG vs PNG
    model.image_mime_type = magic.file(file.file)
    model.image_format = FORMATS_FOR_CONTENT_TYPE[model.image_mime_type]
    model.image_size = File.stat(file.file).size
    if model.image_mime_type == 'video/webm'
      model.image_width, model.image_height = analyze(:dimensions, file.file)
      model.is_animated = true
    else
      image = MiniMagick::Image.open(file.file)
      model.image_width, model.image_height = analyze(:dimensions, image)
      model.is_animated = model.image_mime_type == 'image/gif' ? (image.frames.count > 1) : false
    end
    model.image_aspect_ratio = (model.image_width.to_f / model.image_height)
    hash = Digest::SHA512.hexdigest(File.read(file.file))
    model.image_sha512_hash = hash
    model.image_orig_sha512_hash ||= hash
  end

  def magic
    @@magic ||= Magic.new(Magic::MIME_TYPE)
  end

  def set_intensities
    preview     = rasterized(animated: false)
    intensities = ImageIntensities.file(preview)
    model.create_intensity(intensities)
  end

  def pre_process!
    run(:pre_process, file.file)
  end

  def set_file_format
    format version_file_ext unless File.extname(file.file) == version_file_ext
  end

  def create_image_versions
    dir = version_dir(hidden: model.hidden_from_users?)
    VERSIONS.each_pair do |type, size|
      w, h = size
      dest_file = "#{dir}/#{type}.#{version_file_ext}"
      if ((w && h) && (model.image_width > w || model.image_height > h)) || content_type =~ /webm/
        if content_type.match?(/webm/)
          run(:create_version, file.file, dest_file, w, h, permissions)
        else
          run(:create_version, rasterized, dest_file, w, h)
        end
      elsif content_type == 'image/svg+xml'
        FileUtils.cp(rasterized, dest_file)
      else
        source_file = "#{root}/#{store_dir}/#{filename}"
        platform_link(source_file, dest_file)
      end
      FileUtils.chmod(permissions, dest_file) rescue nil
    end

    # Magic for SVG.
    if content_type == 'image/svg+xml'
      source_file = "#{root}/#{store_dir}/#{filename}"
      full_svg = "#{dir}/full.svg"
      platform_link(source_file, full_svg)
      FileUtils.chmod(permissions, full_svg) rescue nil
    end
    # Magic for WebM
    run(:other_process, file.file, dir) if content_type == 'video/webm'
  end

  def post_process!
    run(:post_process, file.file)
  end

  def generate_webm
    output_file = "#{version_dir(hidden: model.hidden_from_users?)}/full".shellescape
    image_path = file.file.shellescape
    `#{Booru::CONFIG.settings[:ffmpeg_binary]} -loglevel quiet -f gif -i #{image_path} -threads 0 -y -pix_fmt yuv420p -c:v libvpx -quality good -cpu-used 0 -crf 6 -b:v 1M -r 25 -an #{output_file}.webm`
    `#{Booru::CONFIG.settings[:ffmpeg_binary]} -loglevel quiet -f gif -i #{image_path} -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -threads 0 -y -pix_fmt yuv420p -c:v libx264 -movflags +faststart -preset medium -crf 18 -maxrate 2M -profile:v main -level 4.0 -r 25 -an #{output_file}.mp4`
  end

  # 1) ImageAnalyzer doesn't work on vector and animated images
  # 2) All thumb versions are rasterized
  def rasterized(animated: true)
    rendered_png = "#{version_dir(hidden: model.hidden_from_users?)}/rendered.png"
    if (content_type == 'image/gif' && !animated) || content_type == 'video/webm'
      median_time = `ffprobe -i #{file.file.shellescape} -show_entries format=duration -v quiet -of csv="p=0"`.to_f / 2
      `#{Booru::CONFIG.settings[:ffmpeg_binary]} -loglevel quiet -n -i #{file.file.shellescape} -ss #{median_time} -frames:v 1 #{rendered_png}`
      rendered_png
    elsif content_type == 'image/svg+xml'
      `nice -n 15 inkscape #{file.file.shellescape} --export-png=#{rendered_png}` unless File.exist?(rendered_png)
      rendered_png
    else
      file.file
    end
  end

  def platform_link(source, destination)
    FileUtils.ln_sf(source, destination)
  rescue Errno::EPROTO
    FileUtils.cp(source, destination)
  end
end
