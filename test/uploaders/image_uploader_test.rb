# frozen_string_literal: true

require 'test_helper'

class ImageUploaderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    queue_adapter.perform_enqueued_jobs = true
  end

  test 'should correctly identify image metadata' do
    setup_image_tests
    assert_equal %w[image/jpeg image/jpeg image/gif image/png image/png image/gif image/jpeg image/svg+xml], @tests.map(&:image_mime_type)
    assert_equal %w[JPEG JPEG GIF PNG PNG GIF JPEG SVG], @tests.map(&:file_type)
    @tests.each do |t|
      t.reload
      assert_equal `du -b #{t.image.path}`.split(' ')[0].to_i, t.image_size

      [:nw, :ne, :sw, :se].each do |i|
        assert_not_nil t.intensity[i]
      end
    end

    animated = [@pinkie_spy_1, @octavia_1]
    animated.each { |t| assert t.is_animated? }
    (@tests - animated).each { |t| assert_not t.is_animated? }
  end

  test 'should detect correct size for animated images' do
    @gif = create(:gif_first_frame_incorrect_size)
    assert_equal [638, 388], [@gif.image_width, @gif.image_height]
  end

  test 'should correctly identify vector images' do
    @vector = create(:vector)
    assert_equal [1024, 1024], [@vector.image_width, @vector.image_height]
    assert_equal 'svg', @vector.image_format
    assert_equal 'image/svg+xml', @vector.image_mime_type
  end

  # Returns true if all thumbnails defined exist for this image and the symlinks point at valid places
  def has_thumbnails?(image)
    ImageUploader::VERSIONS.each_pair do |version, _|
      path = image.image.version_path(version, hidden: image.hidden_from_users?)
      next if File.exist?(path) && (File.symlink?(path) ? File.exist?(File.readlink(path)) : true) rescue nil
      return false
    end
    true
  end

  test 'should generate thumbnails' do
    setup_image_tests
    @tests.each do |t|
      t.reload
      assert ImageRepairer.new(t).image_readable?
      assert has_thumbnails?(t)
    end
  end

  test 'should change thumb paths when hidden' do
    @image = create(:image)

    @image.save!
    unhidden_path = @image.image.version_dir(hidden: @image.hidden_from_users?)

    ImageHider.new(@image, reason: 'Exterminate!').save
    hidden_path = @image.image.version_dir(hidden: @image.hidden_from_users?)
    assert_not_equal unhidden_path, hidden_path

    ImageUnhider.new(@image).save
    assert_equal unhidden_path, @image.image.version_dir(hidden: @image.hidden_from_users?)
  end

  test 'should rotate JPEG images that have EXIF orientation' do
    @jpeg = create(:jpeg_exif_orientation) # 180°

    # compare intensities to assert that the image was rotated by 180°
    compare_ints = ->(ints_before, ints_after, message) do
      assert_int = ->(k1, k2, msg) { assert_in_delta ints_before[k1], ints_after[k2], 0.2, msg } # allow some wiggle room for thumbs and lossy rotation
      # Original is:   180° rotation should result in:
      #   NW | NE                  SE | SW
      #   SW | SE                  NE | NW
      assert_int.call :nw, :se, message
      assert_int.call :ne, :sw, message
      assert_int.call :sw, :ne, message
      assert_int.call :se, :nw, message
    end

    ints_before = ImageIntensities.file(@jpeg.source_url) # the original image
    compare_ints.call ints_before, ImageIntensities.file(@jpeg.image.path), 'source image'
  end

  test 'Image#destroy_content! should destroy the image files if it was hidden' do
    @image = create(:image)

    original_path = @image.image.path

    @image.save!
    ImageHider.new(@image, reason: '>.<').save
    ImageDestroyer.new(@image).save

    # Ensure the image file content has been fully deleted.
    # This is particularly of utmost priority.
    assert_not File.exist?(original_path)
    assert_not File.exist?(@image.image.version_dir(hidden: true))
    assert_not File.exist?(@image.image.version_dir(hidden: false))
  end

  def setup_image_tests
    # Note that processing all test fixtures takes a while. Only call this method if you really need it.
    @dedupe_1 = create(:dedupe_image_1)
    @dedupe_2 = create(:dedupe_image_2)
    @pinkie_spy_1 = create(:pinkie_spy_1)
    @pinkie_spy_2 = create(:pinkie_spy_2)
    @pinkie_not_spy = create(:pinkie_not_spy)
    @octavia_1 = create(:octavia_1)
    @octavia_2 = create(:octavia_2)
    @vector = create(:vector)
    @tests = [@dedupe_1, @dedupe_2, @pinkie_spy_1, @pinkie_spy_2, @pinkie_not_spy, @octavia_1, @octavia_2, @vector]
  end
end
