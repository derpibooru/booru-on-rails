# frozen_string_literal: true

require 'test_helper'

class GalleriesControllerTest < ActionController::TestCase
  setup do
    @gallery = create(:gallery)
    refresh_index Gallery
  end

  test 'should get index' do
    get :index, params: { user: @gallery.creator.name }
    assert_response :success
    assert_not_nil assigns(:galleries)
  end

  test 'should show gallery' do
    get :show, params: { id: @gallery.id }
    assert_response :success
  end

  test 'should destroy gallery' do
    sign_in @gallery.creator
    assert_difference(-> { Gallery.count }, -1) do
      delete :destroy, params: { id: @gallery }
      refresh_index Gallery
    end
    assert_redirected_to galleries_path
  end
end
