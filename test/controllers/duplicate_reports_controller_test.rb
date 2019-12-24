# frozen_string_literal: true

require 'test_helper'

class DuplicateReportsControllerTest < ActionController::TestCase
  setup do
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should not get index by default' do
    get :index
    assert_response :redirect
    assert_redirected_to root_url
  end

  test 'should not get index for logged in users' do
    sign_in create(:user)
    get :index
    assert_response :redirect
    assert_redirected_to root_url
  end

  test 'should get index for qualified staff' do
    sign_in create(:moderator)
    get :index
    assert_response :success

    sign_in create(:dupe_assistant)
    get :index
    assert_response :success
  end

  test 'should get show for qualified staff' do
    @duplicate_report = create(:duplicate_report)

    sign_in create(:moderator)
    get :show, params: { id: @duplicate_report }
    assert_response :success

    sign_in create(:dupe_assistant)
    get :show, params: { id: @duplicate_report }
    assert_response :success
  end

  test 'should not create when signed out' do
    @dedupe_image_1 = create(:dedupe_image_1)
    @dedupe_image_2 = create(:dedupe_image_2)

    assert_no_difference('DuplicateReport.count') do
      post :create, params: { image_id: @dedupe_image_1.id, duplicate_of_image_id: @dedupe_image_2.id }
      assert_response :redirect
    end
  end

  test 'should create when signed in' do
    sign_in create(:user)
    @dedupe_image_1 = create(:dedupe_image_1)
    @dedupe_image_2 = create(:dedupe_image_2)

    assert_difference('DuplicateReport.count') do
      post :create, params: { image_id: @dedupe_image_1.id, duplicate_of_image_id: @dedupe_image_2.id }

      assert_response :redirect
      assert_redirected_to short_image_path(@dedupe_image_1)
    end
  end
end
