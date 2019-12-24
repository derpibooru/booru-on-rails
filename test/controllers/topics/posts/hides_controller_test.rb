# frozen_string_literal: true

require 'test_helper'

class Topics::Posts::HidesControllerTest < ActionController::TestCase
  setup do
    @topic = create(:topic_with_posts)
    @forum = @topic.forum
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'can be hidden' do
    @post = @topic.posts.last
    sign_in create(:moderator)

    post :create, params: { forum_id: @topic.forum, topic_id: @topic, post_id: @post, deletion_reason: 'Because I feel like it' }

    @post.reload
    assert_response :redirect
    assert_redirected_to short_topic_post_path(@topic.forum, @topic, @post, anchor: "post_#{@post.id}")
    assert @post.hidden_from_users
  end

  test 'should hide topic when hidden if first post' do
    @post = @topic.posts.detect(&:first?)
    sign_in create(:moderator)

    post :create, params: { forum_id: @topic.forum, topic_id: @topic, post_id: @post, deletion_reason: 'Bye bye topic' }

    @topic.reload
    assert @topic.hidden_from_users
  end

  test 'should keep posts hidden with the same metadata when hide requested again.' do
    @post = @topic.posts.last
    @user_a = create(:moderator)
    PostHider.new(@post, user: @user_a, reason: 'Get out.').save

    @user_b = create(:moderator)
    sign_in @user_b

    post :create, params: { forum_id: @topic.forum, topic_id: @topic, post_id: @post, deletion_reason: 'I BELIEVE I SAID GET OUT' }

    assert_response :redirect
    @post.reload
    assert @post.hidden_from_users
    assert_equal @user_a, @post.deleted_by
    assert_equal 'Get out.', @post.deletion_reason
  end

  test 'forbids deletion without reason' do
    @post = @topic.posts.last
    sign_in create(:moderator)
    post :create, params: { forum_id: @topic.forum, topic_id: @topic, post_id: @post, deletion_reason: '' }

    @post.reload
    assert_response :redirect
    assert_not @post.hidden_from_users
  end

  test 'should hide threads with same user when hidden post is the OP' do
    @post = @topic.posts.first
    @luser = create(:moderator)
    sign_in @luser
    post :create, params: { forum_id: @topic.forum, topic_id: @topic, post_id: @post, deletion_reason: 'test op hide' }

    @topic.reload
    assert_response :redirect
    assert @topic.hidden_from_users
    assert_equal 'test op hide', @topic.deletion_reason
    assert_equal @luser, @topic.deleted_by
  end
end
