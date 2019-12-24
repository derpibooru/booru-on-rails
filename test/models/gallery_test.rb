# frozen_string_literal: true

require 'test_helper'
require 'image_loader'

class GalleryTest < ActiveSupport::TestCase
  test 'inserting images creates interactions and updates indexes' do
    images = gallery_images
    assert_equal images.size, @gallery.gallery_interactions.size

    search = search_gallery_images
    assert_equal images.size, search.size
    images.each_with_index do |image, i|
      assert_equal image.id, search.records[i].id
    end
  end

  test 'images can be removed' do
    images = gallery_images

    @gallery.remove(images[0]).reload
    images.delete images[0]

    assert_equal images.size, @gallery.gallery_interactions.size
    assert_equal images.size, search_gallery_images.size
  end

  test 'gallery is destroyable' do
    gallery_images
    @gallery.destroy

    assert_equal 0, @gallery.gallery_interactions.count
    assert_equal 0, search_gallery_images.size
  end

  def search_gallery_images
    refresh_index Image
    ImageLoader.new.gallery(@gallery.id).records
  end

  def gallery_images
    @gallery = create(:gallery)

    images = create_list(:image_skips_validation, 4)

    images.each { |i| @gallery.add(i) }
    images.reverse # images are ordered by time added, descending
  end
end
