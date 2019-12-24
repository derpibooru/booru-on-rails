# frozen_string_literal: true

require 'test_helper'

class ChannelsControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:channels)
  end

  test 'should get show' do
    @channel = create(:livestream_channel)
    get :show, params: { id: @channel }
    assert_redirected_to @channel.url
  end
end
