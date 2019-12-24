# frozen_string_literal: true

require 'test_helper'

class Images::HidesControllerTest < ActionController::TestCase
  setup do
    @image = create(:image)
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'image hiding should require a reason' do
    sign_in create(:moderator)

    post :create, params: { image_id: @image.id }

    @image.reload
    assert_response :redirect
    assert_not @image.hidden_from_users
  end

  test 'image hiding should hide images using controller-provided information' do
    @user = create(:moderator)
    sign_in @user

    post :create, params: { image_id: @image.id, deletion_reason: 'Get out.' }

    @image.reload
    assert_response :redirect
    assert @image.hidden_from_users
    assert_equal @user, @image.deleted_by
    assert_equal 'Get out.', @image.deletion_reason
  end

  test 'image deletion requests after a deleted image should keep metadata the same' do
    @user_a = create(:moderator)
    ImageHider.new(@image, user: @user_a, reason: 'Get out.').save

    @user_b = create(:moderator)
    sign_in @user_b

    post :create, params: { image_id: @image.id, deletion_reason: 'yo mama' }

    @image.reload
    assert_response :redirect
    assert @image.hidden_from_users
    assert_equal @user_a, @image.deleted_by
    assert_equal 'Get out.', @image.deletion_reason
  end
end
