# frozen_string_literal: true

require 'test_helper'

class InteractionTest < ActiveSupport::TestCase
  setup do
    @subject = create(:image)
    @user = create(:user)
  end

  test 'voting without a user fails' do
    assert_raises ActiveRecord::RecordInvalid do
      @subject.upvotes.create!(user: nil, up: true)
    end
  end

  test 'voting up given no existing vote should upvote the subject' do
    @subject.votes.create(user: @user, up: true)
    assert_equal 1, @subject.upvotes.count
    assert_equal 1, @subject.score
  end

  test 'voting down given no existing vote should downvote the subject' do
    @subject.votes.create(user: @user, up: false)
    assert_equal 1, @subject.downvotes.count
    assert_equal(-1, @subject.score)
  end

  test 'voting false given no existing vote should do nothing' do
    @subject.votes.where(user: @user).destroy_all
    assert_equal 0, @subject.votes.count
    assert_equal 0, @subject.score
  end

  test 'voting up given an upvote should do nothing' do
    @subject.votes.create(user: @user, up: true)
    @subject.votes.create(user: @user, up: true)
    assert_equal 1, @subject.upvotes.count
    assert_equal 1, @subject.score
  end

  test 'voting down given an upvote should downvote the subject' do
    @subject.votes.create(user: @user, up: true)
    @subject.votes.create(user: @user, up: false)
    assert_equal 0, @subject.upvotes.count
    assert_equal 1, @subject.downvotes.count
    assert_equal(-1, @subject.score)
  end

  test 'voting false given an upvote should redact the upvote' do
    @subject.votes.create(user: @user, up: true)
    @subject.votes.where(user: @user).destroy_all
    assert_equal 0, @subject.votes.count
    assert_equal 0, @subject.score
  end

  test 'voting up given a downvote should upvote the subject' do
    @subject.votes.create(user: @user, up: false)
    @subject.votes.create(user: @user, up: true)
    assert_equal 1, @subject.upvotes.count
    assert_equal 0, @subject.downvotes.count
    assert_equal 1, @subject.score
  end

  test 'voting down given a downvote should do nothing' do
    @subject.votes.create(user: @user, up: false)
    @subject.votes.create(user: @user, up: false)
    assert_equal 1, @subject.downvotes.count
    assert_equal(-1, @subject.score)
  end

  test 'voting false given a downvote should redact the downvote' do
    @subject.votes.create(user: @user, up: false)
    @subject.votes.where(user: @user).destroy_all
    assert_equal 0, @subject.votes.count
    assert_equal 0, @subject.score
  end

  test 'faving without a user fails' do
    assert_raises ActiveRecord::RecordInvalid do
      @subject.faves.create!(user: nil)
    end
  end

  test 'faving true given no existing fave should fave the subject' do
    @subject.faves.create(user: @user)
    assert_equal 1, @subject.faves.count
    assert_equal 1, @subject.faves_count
  end

  test 'faving false given no existing fave should do nothing' do
    @subject.faves.where(user: @user).destroy_all
    assert_equal 0, @subject.faves.count
    assert_equal 0, @subject.faves_count
  end

  test 'faving true given an existing fave should do nothing' do
    @subject.faves.create(user: @user)
    @subject.faves.create(user: @user)
    assert_equal 1, @subject.faves.count
    assert_equal 1, @subject.faves_count
  end

  test 'faving false given an existing fave should redact the fave' do
    @subject.faves.create(user: @user)
    @subject.faves.where(user: @user).destroy_all
    assert_equal 0, @subject.faves.count
    assert_equal 0, @subject.faves_count
  end
end
