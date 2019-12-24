# frozen_string_literal: true

require 'test_helper'

class Image::VoteMigrationTest < ActiveSupport::TestCase
  setup do
    @source   = create(:dedupe_image_1)
    @target   = create(:dedupe_image_2)
    @upuser   = create(:user)
    @downuser = create(:user)
  end

  test 'should correctly move all interactions' do
    @source.votes.create(user: @downuser, up: false)
    @source.votes.create(user: @upuser, up: true)
    @source.faves.create(user: @upuser)

    Image::VoteMigration.new(source: @source, target: @target).save

    @target.reload

    assert_equal @source.downvotes_count, 1
    assert_equal @source.upvotes_count, 1
    assert_equal @source.faves_count, 1

    assert_equal @source.downvotes.count, 1
    assert_equal @source.upvotes.count, 1
    assert_equal @source.faves.count, 1

    assert_equal @target.downvotes_count, 1
    assert_equal @target.upvotes_count, 1
    assert_equal @target.faves_count, 1

    assert_equal @target.downvotes.count, 1
    assert_equal @target.upvotes.count, 1
    assert_equal @target.faves.count, 1
  end
end
