# frozen_string_literal: true

require 'test_helper'
require 'image_loader'

class GalleryReorderJobTest < ActiveJob::TestCase
  setup do
    @gallery = create(:gallery)
    @images = create_list(:image_skips_validation, 4)

    perform_enqueued_jobs do
      @images.each { |i| @gallery.add i }
    end
  end

  test 'rearranges a full set of images' do
    reorder images: ([1, 2, 0, 3].map { |i| @images[i].id })
    @images.reverse!
    @gallery.update_attribute :order_position_asc, true
    reorder images: ([1, 2, 0, 3].map { |i| @images[i].id })
  end

  test 'rearranges a subset with in-between items missing (due to filters)' do
    limited = [3, 0, 1].map { |i| @images[i].id }
    result = [3, 2, 0, 1].map { |i| @images[i].id }
    reorder images: limited, expect: result
  end

  def reorder(images:, expect: images)
    GalleryReorderJob.perform_now @gallery.id, images

    assert_equal expect, @gallery.gallery_interactions.order(position: @gallery.position_order).map(&:image_id)
    assert_equal expect, search_gallery_images.map(&:id)
  end

  def search_gallery_images
    refresh_index Image
    ImageLoader.new.gallery(@gallery.id, @gallery.position_order).records
  end
end
