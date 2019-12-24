# frozen_string_literal: true

require 'test_helper'

class Images::Comments::HidesControllerTest < ActionController::TestCase
  def setup
    @image = create(:image)
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should hide comments' do
    @comment = create(:comment, image_id: @image.id)
    @user = create(:moderator)
    sign_in @user

    post :create, params: { comment_id: @comment, image_id: @comment.image, deletion_reason: 'Getouttaheya' }
    assert_response :redirect
    assert_redirected_to image_path(@comment.image, anchor: "comment_#{@comment.id}")
    @comment.reload
    assert @comment.hidden_from_users
    assert_equal @user, @comment.deleted_by
    assert_equal 'Getouttaheya', @comment.deletion_reason
  end

  test 'should not hide comments if no reason is provided' do
    @comment = create(:comment, image_id: @image.id)
    @user = create(:moderator)
    sign_in @user

    post :create, params: { comment_id: @comment, image_id: @comment.image }

    @comment.reload
    assert_not @comment.hidden_from_users
  end

  test 'should keep comments hidden with the same metadata when hide requested again' do
    @comment = create(:comment, image_id: @image.id)
    @user_a = create(:moderator)
    ReportableHider.new(@comment, user: @user_a, reason: 'Get out.').save

    @user_b = create(:moderator)
    sign_in @user_b

    post :create, params: { comment_id: @comment, image_id: @comment.image, deletion_reason: 'I BELIEVE I SAID GET OUT' }

    assert_response :redirect
    @comment.reload
    assert @comment.hidden_from_users
    assert_equal @user_a, @comment.deleted_by
    assert_equal 'Get out.', @comment.deletion_reason
  end
end
