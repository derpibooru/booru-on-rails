# frozen_string_literal: true

require 'test_helper'

class ForumsControllerTest < ActionController::TestCase
  setup do
    @forum = create(:forum)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert assigns(:forums)
  end

  test 'should get show' do
    get :show, params: { id: @forum.short_name }
    assert_response :success
    assert_equal @forum, assigns(:forum)
  end
end
