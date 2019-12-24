# frozen_string_literal: true

require 'test_helper'

class Topics::PostsControllerTest < ActionController::TestCase
  setup do
    @topic = create(:topic_with_posts)
    @forum = @topic.forum
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should post to unlocked, undeleted topic when logged out' do
    assert_difference('Post.count') do
      post :create, params: { forum_id: @forum, topic_id: @topic, post: { body: 'Post body' } }
      assert_response :redirect
      @post = assigns(:post)
      assert_not_nil @post
      assert_redirected_to short_topic_post_path(@forum, @topic, @post, anchor: "post_#{@post.id}")
      assert_equal 7, @post.topic_position # 6 posts already existed, see factory
    end
  end

  test 'should post to unlocked, undeleted topic when signed in' do
    @user = create(:user)
    sign_in @user

    assert_difference('Post.count') do
      post :create, params: { forum_id: @forum, topic_id: @topic, post: { body: 'Post body' } }
      assert_response :redirect
      @post = assigns(:post)
      assert_not_nil @post
      assert_redirected_to short_topic_post_path(@forum, @topic, @post, anchor: "post_#{@post.id}")
      assert_equal 7, @post.topic_position # 6 posts already existed, see factory
      assert_equal @user, @post.user
    end
  end

  test 'cannot create posts on a locked topic' do
    @topic = create(:locked_topic_with_posts)
    @forum = @topic.forum

    assert_no_difference('Post.count') do
      post :create, params: { forum_id: @forum, topic_id: @topic, post: { body: 'Post body' } }
      assert_response :redirect
      assert_redirected_to root_url
    end
  end

  test 'cannot create posts on a deleted topic' do
    @topic = create(:deleted_topic_with_posts)
    @forum = @topic.forum

    assert_no_difference('Post.count') do
      post :create, params: { forum_id: @forum, topic_id: @topic, post: { body: 'Post body' } }
      assert_response :redirect
      assert_redirected_to root_url
    end
  end

  test 'should get edit' do
    @post = create(:post_as_user)
    @topic = @post.topic
    sign_in @post.user

    get :edit, params: { forum_id: @topic.forum, topic_id: @topic, id: @post }
    assert_response :success
  end

  test 'can update posts' do
    @post = create(:post_as_user)
    @topic = @post.topic
    @forum = @topic.forum
    sign_in @post.user

    put :update, params: { forum_id: @forum, topic_id: @topic, id: @post, post: { body: 'Updated' } }
    @post.reload
    assert_response :redirect
    assert_redirected_to short_topic_post_path(@forum, @topic, @post, anchor: "post_#{@post.id}")
    assert_equal 'Updated', @post.body
  end

  test 'cannot update posts in a locked topic' do
    @topic = create(:locked_topic_with_posts)
    @post = @topic.posts.last
    @user = @post.user
    sign_in @user

    put :update, params: { forum_id: @forum, topic_id: @topic, id: @post, post: { body: 'Updated' } }
    @post.reload
    assert_response :redirect
    assert_redirected_to root_url
  end

  test 'cannot update posts in a deleted topic' do
    @topic = create(:deleted_topic_with_posts)
    @post = @topic.posts.last
    @user = @post.user
    sign_in @user

    put :update, params: { forum_id: @forum, topic_id: @topic, id: @post, post: { body: 'Updated' } }
    @post.reload
    assert_response :redirect
    assert_redirected_to root_url
  end
end
