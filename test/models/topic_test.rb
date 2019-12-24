# frozen_string_literal: true

require 'test_helper'

class TopicTest < ActiveSupport::TestCase
  setup do
    @topic = build(:topic)
  end

  test 'should be valid' do
    assert @topic.valid?
  end

  test '#page_for_post should return the correct page for posts' do
    @topic = create(:topic)
    @posts = []
    26.times { @posts << create(:post, topic: @topic) }
    @topic.reload
    assert_equal 1, @topic.page_for_post(@posts[0].id)
    assert_equal 1, @topic.page_for_post(@posts[23].id)
    assert_equal 2, @topic.page_for_post(@posts[24].id)
    assert_equal 2, @topic.page_for_post(@posts[25].id)
  end

  test 'should set its slug' do
    @topic.save
    assert @topic.slug.present?
  end

  test 'should choose a unique slug correctly for identical names in differing forums' do
    @topic.title = 'This is a title'
    @topic.save
    @forum2 = create(:forum)
    @topic2 = create(:topic, title: 'This is a title', forum: @forum2)

    assert_equal @topic2.slug, @topic.slug
  end

  test 'should choose a unique slug correctly for identical names in the same forum' do
    @topic.title = 'This is a title'
    @topic.save
    assert_not_equal Topic.generate_unique_slug('This is a title', @topic.forum.id), @topic.slug
  end

  test 'should update its forum when created' do
    assert_difference('@topic.forum.topic_count') { @topic.save }
  end

  test "should update its author's topic count when created" do
    assert_difference('@topic.user.topic_count') { @topic.save }
  end

  test 'should update its forum when deleted' do
    @topic = create(:topic_with_posts)
    assert_difference('@topic.forum.topic_count', -1) do
      TopicHider.new(@topic, reason: 'Because the test environment is a harsh place').save
    end
  end

  test "should decrement its forum's post count when deleted" do
    @topic = create(:topic_with_posts)
    assert_difference('@topic.forum.post_count', -@topic.post_count) do
      TopicHider.new(@topic, reason: 'Because the test environment is a harsh place').save
    end
  end

  test '#move_to_forum! migrates completely to the new forum' do
    @target_forum = create(:forum)
    @old_forum = create(:forum)
    @topic = create(:topic_with_posts, forum: @old_forum)
    @topic.save

    assert_equal 1, @old_forum.topic_count
    # assert_equal @topic.post_count, @old_forum.post_count
    # assert_equal @topic.last_post, @old_forum.last_post

    @topic.move_to_forum!(@target_forum)

    @target_forum.reload
    @old_forum.reload

    assert_equal 0, @old_forum.topic_count
    assert_equal 0, @old_forum.post_count
    assert_nil @old_forum.last_post

    assert_equal 1, @target_forum.topic_count
    assert_equal @topic.post_count, @target_forum.post_count
    assert_equal @topic.last_post, @target_forum.last_post
  end
end
