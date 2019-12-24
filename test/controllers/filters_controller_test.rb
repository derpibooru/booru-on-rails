# frozen_string_literal: true

require 'test_helper'

class FiltersControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should get show for system filters' do
    @filter = filters(:default)
    get :show, params: { id: @filter }
    assert_response :success
  end

  test 'should get new' do
    sign_in create(:user)
    get :new
    assert_response :success
  end

  test 'should create a filter' do
    sign_in create(:user)

    assert_difference('Filter.count') do
      post :create, params: { filter: {
        spoilered_tag_list:    'questionable,suggestive',
        hidden_tag_list:       'explicit,semi-grimdark,grimdark,grotesque',
        description:           'Basically the default filter',
        name:                  'Test Default Copy',
        public:                false,
        spoilered_complex_str: '',
        hidden_complex_str:    ''
      } }

      assert_response :redirect
      assert assigns(:filter)
    end
  end

  test 'should get edit when signed in' do
    @filter = create(:user_filter)
    sign_in @filter.user

    get :edit, params: { id: @filter }
    assert_response :success
  end

  test 'should put update' do
    @filter = create(:user_filter)
    sign_in @filter.user

    put :update, params: { id: @filter, filter: {
      spoilered_complex_str: 'score.lt:50'
    } }

    assert_response :redirect
    assert_redirected_to @filter
  end

  test 'should delete user filters' do
    @filter = create(:user_filter)
    sign_in @filter.user

    delete :destroy, params: { id: @filter }
    assert_not Filter.where(id: @filter.id).exists?
  end

  test 'should not delete system filters' do
    @filter = filters(:default)
    sign_in create(:user)

    assert_no_difference('Filter.count') do
      delete :destroy, params: { id: @filter }
    end
  end
end
