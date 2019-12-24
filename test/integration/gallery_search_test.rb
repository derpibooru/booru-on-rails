# frozen_string_literal: true

require 'test_helper'

class GallerySearchTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    @user = create(:user)
    @galleries = create_list(:gallery, 4)
    refresh_index Gallery
    login_as @user
  end

  test 'destroying a gallery removes it from search' do
    login_as @galleries.first.creator
    assert_difference(-> { gallery_search(show_empty: true); json_response.size }, -1) do
      delete gallery_path(@galleries)
      refresh_index Gallery
    end
  end

  test 'searching general fields' do
    assert_single_search { |g| { title: g.title[10..-1], show_empty: true } }
    assert_single_search { |g| { creator: g.creator.name, show_empty: true } }
  end

  test 'searching image-dependent fields' do
    image = create(:image_skips_validation)
    sample = [@galleries[1], @galleries[2]]
    image_dependent_params = [{ show_empty: false }, { include_image: image.id }]
    image_dependent_params.each do |p|
      assert_dependent_param p, image, sample
    end
  end

  test 'searching subscriptions' do
    perform_enqueued_jobs do
      put '/api/v2/notifications/watch', params: { format: :json, id: @galleries.first.id, actor_class: 'Gallery' }
    end
    assert_response :success
    refresh_index Gallery

    gallery_search(my_subs: true, show_empty: true)
    assert_equal([@galleries.first.id], json_response.map { |g| g['id'] })

    perform_enqueued_jobs do
      put '/api/v2/notifications/unwatch', params: { format: :json, id: @galleries.first.id, actor_class: 'Gallery' }
    end
    assert_response :success
    refresh_index Gallery

    gallery_search(my_subs: true, show_empty: true)
    assert_equal 0, json_response.size
  end

  def gallery_search(query)
    query.except! :show_empty unless query[:show_empty]
    query[:format] = :json
    get galleries_path, params: query
  end

  def assert_single_search
    @galleries.each do |g|
      gallery_search yield(g)
      assert_equal 1, json_response.size
      assert_equal g.id, json_response.first['id']
    end
  end

  def assert_dependent_param(query, image, sample)
    perform_enqueued_jobs do
      sample.each { |g| g.add image }
    end
    refresh_index Gallery

    gallery_search(query)
    assert_equal sample.size, json_response.size
    assert_equal sample.map(&:id).sort, json_response.map { |g| g['id'] }.sort

    perform_enqueued_jobs do
      sample.each { |g| g.remove image }
    end
    refresh_index Gallery

    gallery_search(query)
    assert_equal 0, json_response.size
  end

  def json_response
    ActiveSupport::JSON.decode @response.body
  end
end
