# frozen_string_literal: true

require 'test_helper'

class TopicsControllerTest < ActionController::TestCase
  setup do
    @topic = create(:topic)
    @forum = @topic.forum
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should get show' do
    get :show, params: { id: @topic, forum_id: @forum }
    assert_response :success
    assert_equal @topic, assigns(:topic)
    assert_equal @forum, assigns(:forum)
  end

  test 'should not get new when signed out' do
    get :new, params: { forum_id: @forum }
    assert_response :redirect
  end

  test 'should get new when signed in' do
    sign_in create(:user)
    get :new, params: { forum_id: @forum }
    assert_response :success
  end

  test 'should not create topic when signed out' do
    assert_no_difference('Topic.count') do
      post :create, params: { forum_id: @forum, topic: {
        title:            'This is a created topic',
        posts_attributes: { '0' => { body: 'This is the content of the first post' } },
        anonymous:        false
      } }

      assert_response :redirect
    end
  end

  test 'should create topic when signed in' do
    @user = create(:user)
    sign_in @user

    assert_difference('Topic.count') do
      post :create, params: { forum_id: @forum, topic: {
        title:            'This is a created topic',
        posts_attributes: { '0' => { body: 'This is the content of the first post' } },
        anonymous:        false
      } }

      assert_response :redirect

      @topic = assigns(:topic)
      assert_not_nil @topic
      @post = @topic.posts.first
      assert_not_nil @post
      assert_equal 'This is the content of the first post', @post.body
      assert_equal 0, @post.topic_position
      assert_equal @user, @post.user
    end
  end
end
