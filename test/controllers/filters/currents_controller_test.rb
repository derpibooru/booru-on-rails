# frozen_string_literal: true

require 'test_helper'

class Filters::CurrentsControllerTest < ActionController::TestCase
  test 'should get show' do
    @default_filter = filters(:default)
    put :update, params: { id: @default_filter }
    get :show
    assert_response :redirect
  end

  test 'should select filters' do
    @default_filter = filters(:default)

    put :update, params: { id: @default_filter }
    assert_response :redirect
    assert_equal @default_filter.id, session[:filter_id]
  end

  test 'should update user counts when logged in' do
    @user_filter = create(:user_filter)
    sign_in @user_filter.user

    put :update, params: { id: @user_filter }

    @user_filter.reload
    assert_response :redirect
    assert_equal @user_filter.id, @user_filter.user.current_filter_id
    assert_equal 1, @user_filter.user.current_filter.user_count
  end
end
