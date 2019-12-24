# frozen_string_literal: true

require 'test_helper'
require 'rack/test'

class ImagesControllerTest < ActionController::TestCase
  setup do
    @image = create(:image)
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert assigns(:images)
  end

  test 'should get show' do
    get :show, params: { id: @image.id }
    assert_response :success
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create a new image' do
    image_file = Rack::Test::UploadedFile.new Rails.root.join('test', 'fixtures', 'image_files', 'dedupe_evade_1.jpeg'), 'image/jpeg'
    assert_difference('Image.count') do
      post :create, params: { image: {
        description: '',
        source_url:  'h',
        tag_input:   'safe, nightmare moon, nightmare dupe',
        image:       image_file
      } }
    end
    assert_redirected_to short_image_path(assigns(:image))
  end

  test 'duplicates should redirect to the target image' do
    @dedupe_1 = create(:dedupe_image_2)
    ImageDuplicateMergeJob.perform_now @image.id, @dedupe_1.id, nil

    get :show, params: { id: @image.id }
    assert_response :redirect
    assert_redirected_to short_image_path(@dedupe_1)
  end

  test 'content destruction of an image should do nothing given a non-hidden image' do
    sign_in create(:moderator)

    delete :destroy, params: { id: @image.id }

    @image.reload
    assert_response :redirect
    assert_redirected_to root_path
    assert_not @image.destroyed_content
  end

  test 'content destruction of an image should remove the image contents' do
    sign_in create(:moderator)
    ImageHider.new(@image, reason: 'The era of deletion is upon us.').save

    delete :destroy, params: { id: @image.id }

    @image.reload
    assert @image.destroyed_content
  end
end
