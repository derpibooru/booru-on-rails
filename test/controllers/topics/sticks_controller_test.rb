# frozen_string_literal: true

require 'test_helper'

class Topics::SticksControllerTest < ActionController::TestCase
  setup do
    @user = create(:moderator)
    @topic = create(:topic)
    @forum = @topic.forum
  end

  test 'can be stuck and unstuck' do
    sign_in create(:moderator)

    post :create, params: { topic_id: @topic, forum_id: @forum }

    @topic.reload
    assert_response :redirect
    assert_redirected_to forum_topic_path(@forum, @topic)
    assert @topic.sticky

    delete :destroy, params: { topic_id: @topic, forum_id: @forum }

    @topic.reload
    assert_response :redirect
    assert_redirected_to forum_topic_path(@forum, @topic)
    assert_not @topic.sticky
  end
end
