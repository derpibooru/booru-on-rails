# frozen_string_literal: true

require 'test_helper'

class Images::CommentsControllerTest < ActionController::TestCase
  def setup
    @image = create(:image)
    @request.cookies['_ses'] = 'c1836832948'
  end

  def setup_user
    @user = create(:user)
    sign_in @user
  end

  test 'should post a comment anonymously' do
    post :create, params: { image_id: @image.id, comment: {
      body:      'Test body',
      anonymous: false
    } }
    @image.reload

    assert_response :redirect
    assert_redirected_to image_path(@image, anchor: "comment_#{@image.comments.first.id}")

    assert_equal 'Test body', @image.comments.first.body
  end

  test 'should post a comment for a user' do
    setup_user

    post :create, params: { image_id: @image.id, comment: {
      body:      'Test body',
      anonymous: false
    } }
    @image.reload

    assert_response :redirect
    assert_redirected_to image_path(@image, anchor: "comment_#{@image.comments.first.id}")

    assert_equal @user, @image.comments.first.user
    assert_equal 'Test body', @image.comments.first.body
  end

  test 'should allow anonymous posting' do
    setup_user

    post :create, params: { image_id: @image.id, comment: {
      body:      'Test body',
      anonymous: true
    } }
    @image.reload

    assert_response :redirect
    assert_redirected_to image_path(@image, anchor: "comment_#{@image.comments.first.id}")

    assert_equal @user, @image.comments.first.user
    assert @image.comments.first.anonymous
    assert_equal 'Test body', @image.comments.first.body
  end
end
