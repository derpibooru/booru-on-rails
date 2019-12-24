# frozen_string_literal: true

require 'test_helper'

class Posts::PostedsControllerTest < ActionController::TestCase
  setup do
    @topic = create(:topic_with_posts)
    @forum = @topic.forum
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should get posted' do
    @post = @topic.posts.last
    @user = @post.user

    get :show, params: { user_id: @user.id }
    assert_response :success
  end
end
