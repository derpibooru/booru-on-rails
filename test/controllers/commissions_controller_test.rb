# frozen_string_literal: true

require 'test_helper'

class CommissionsControllerTest < ActionController::TestCase
  setup do
    @commission = create(:commission)
  end

  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should show commission' do
    get :show, params: { id: @commission }
    assert_response :success
  end
end
