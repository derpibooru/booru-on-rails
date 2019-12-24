# frozen_string_literal: true

require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  setup do
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should create report when signed out' do
    @image = create(:image)

    assert_difference('Report.count') do
      post :create, params: { reportable_class: 'Image', reportable_id: @image.id, report: { reason: 'OP IS A DUCK' }, category: 'Rule #0' }

      assert_response :redirect
      assert_redirected_to reports_path
    end
  end

  test 'should create report when signed in' do
    sign_in create(:user)
    @image = create(:image)

    assert_difference('Report.count') do
      post :create, params: { reportable_class: 'Image', reportable_id: @image.id, report: { reason: 'OP IS A DUCK' }, category: 'Rule #0' }

      assert_response :redirect
      assert_redirected_to reports_path
    end
  end

  test 'should get new for all reportable models' do
    @comment = create(:comment)
    @image = @comment.image
    @post = create(:post)
    @filter = create(:user_filter)
    @user = @filter.user

    [@comment, @image, @post, @filter, @user].each do |reportable|
      get :new, params: { reportable_class: reportable.class.to_s, reportable_id: reportable.id }
      assert_response :success
    end
  end

  test 'should create reports for all reportable models' do
    @comment = create(:comment)
    @image = @comment.image
    @post = create(:post)
    @filter = create(:user_filter)
    @user = @filter.user

    [@comment, @image, @post, @filter, @user].each do |reportable|
      assert_difference('Report.count') do
        post :create, params: { reportable_class: reportable.class.to_s, reportable_id: reportable.id, report: { reason: 'OP IS A DUCK' }, category: 'Rule #0' }

        assert_response :redirect
        assert_redirected_to reports_path
      end
    end
  end
end
