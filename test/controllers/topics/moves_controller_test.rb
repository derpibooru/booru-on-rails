# frozen_string_literal: true

require 'test_helper'

class Topics::MovesControllerTest < ActionController::TestCase
  setup do
    @target_forum = create(:forum_with_topics)
    @user = create(:moderator)
    @topic = create(:topic)
    @forum = @topic.forum
  end

  test 'can be moved' do
    sign_in @user

    post :create, params: { topic_id: @topic, forum_id: @forum, target_forum_id: @target_forum }

    @topic.reload
    assert_response :redirect
    assert_redirected_to forum_topic_path(@target_forum, @topic)
  end
end
