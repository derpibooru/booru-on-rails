# frozen_string_literal: true

require 'test_helper'

class PostTest < ActiveSupport::TestCase
  setup do
    @post = build(:post)
  end

  test 'should be valid' do
    assert @post.valid?
  end

  test 'should update its parents on creation' do
    forum_count = @post.topic.forum.post_count
    topic_count = @post.topic.post_count

    @post.save!
    @post.reload
    assert_equal forum_count + 1, @post.topic.forum.post_count
    assert_equal topic_count + 1, @post.topic.post_count
    assert_equal @post, @post.topic.forum.last_post
    assert_equal @post.topic, @post.topic.forum.last_topic
  end

  test 'should update its parents when deleted' do
    @post.save

    PostHider.new(@post, reason: 'test system deletion').save

    assert_not_equal @post.topic.forum.last_post, @post
    assert_not_equal @post.topic.last_post, @post
  end

  test 'should close open reports when hidden' do
    @report = create(:report_of_post)
    @post = @report.reportable
    PostHider.new(@post, reason: 'I just want to close the report.').save

    @report.reload
    assert_equal 'closed', @report.state
  end

  test 'should hide threads when hidden post is the OP' do
    @post.save!

    PostHider.new(@post.topic.posts.first, reason: 'test OP deletion').save

    @post.topic.reload
    assert @post.topic.hidden_from_users
    assert_equal 'test OP deletion', @post.topic.deletion_reason
  end
end
