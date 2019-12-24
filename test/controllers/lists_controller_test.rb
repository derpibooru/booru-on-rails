# frozen_string_literal: true

require 'test_helper'

class ListsControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:top_scoring_images)
    assert_not_nil assigns(:all_time_top_scoring_images)
    assert_not_nil assigns(:top_commented_images)
  end

  test 'should get recent comments' do
    get :recent_comments
    assert_response :success
    assert_not_nil assigns(:recent_comments)
  end

  test 'should list user comments' do
    @comment = create(:comment_as_user)
    @user = @comment.user

    get :my_comments, params: { user_id: @user.id }
    assert_response :success
    assert_not_nil assigns(:my_comments)
  end

  test 'should list my comments' do
    @comment = create(:comment_as_user)
    sign_in @comment.user

    get :my_comments
    assert_response :success
    assert_not_nil assigns(:my_comments)
  end
end
