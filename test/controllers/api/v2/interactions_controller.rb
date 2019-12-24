# frozen_string_literal: true

require 'test_helper'

class Api::V2::InteractionsControllerTest < ActionController::TestCase
  setup do
    @image = create(:image)
    @request.cookies['_ses'] = 'c1836832948'
    @user = create(:user)
    sign_in @user
  end

  test 'upvoting should upvote an image' do
    assert_equal 0, @image.upvotes_count
    put :vote, params: { id: @image.id, value: 'up' }

    @image.reload
    assert_equal 1, @image.upvotes_count
    assert_equal 0, @image.downvotes_count
    assert_equal 0, @image.faves_count
  end

  test 'downvoting should downvote an image' do
    assert_equal 0, @image.downvotes_count
    put :vote, params: { id: @image.id, value: 'down' }

    @image.reload
    assert_equal 1, @image.downvotes_count
    assert_equal 0, @image.upvotes_count
    assert_equal 0, @image.faves_count
  end

  test 'can remove a vote' do
    @image.votes.create(user: @user, up: true)
    assert_equal 1, @image.upvotes_count
    put :vote, params: { id: @image.id, value: 'false' }

    @image.reload
    assert_equal 0, @image.upvotes_count
  end

  test 'faving should add an upvote' do
    assert_equal 0, @image.faves_count
    put :fave, params: { id: @image.id, value: 'true' }

    @image.reload
    assert_equal 1, @image.faves_count
    assert_equal 1, @image.upvotes_count
  end

  test 'unfaving should leave the upvote in place' do
    @image.votes.create(user: @user, up: true)
    @image.faves.create(user: @user)
    assert_equal 1, @image.faves_count
    assert_equal 1, @image.upvotes_count

    put :fave, params: { id: @image.id, value: 'false' }

    @image.reload
    assert_equal 0, @image.faves_count
    assert_equal 1, @image.upvotes_count
  end
end
