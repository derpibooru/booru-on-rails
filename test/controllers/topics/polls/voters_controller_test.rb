# frozen_string_literal: true

require 'test_helper'

class Topics::Polls::VotersControllerTest < ActionController::TestCase
  setup do
    @topic = create(:topic_with_poll)
    @forum = @topic.forum
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should not list voters when unauthenticated' do
    get :index, params: { forum_id: @forum, topic_id: @topic }

    assert_response :redirect
    assert_redirected_to root_url
  end

  test 'should list voters when authenticated' do
    @user = create(:moderator)
    sign_in @user

    get :index, params: { forum_id: @forum, topic_id: @topic }

    assert_response :success
  end
end
