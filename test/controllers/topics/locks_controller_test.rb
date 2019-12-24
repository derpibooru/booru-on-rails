# frozen_string_literal: true

require 'test_helper'

class Topics::LocksControllerTest < ActionController::TestCase
  setup do
    @user = create(:moderator)
    @topic = create(:topic)
    @forum = @topic.forum
  end

  test 'can be locked and unlocked' do
    sign_in @user

    post :create, params: { topic_id: @topic, forum_id: @forum, lock_reason: 'Because I feel like it' }

    @topic.reload
    assert_response :redirect
    assert_redirected_to forum_topic_path(@forum, @topic)
    assert_not_nil @topic.locked_at
    assert_equal @user, @topic.locked_by
    assert_equal 'Because I feel like it', @topic.lock_reason

    delete :destroy, params: { topic_id: @topic, forum_id: @forum }

    @topic.reload
    assert_response :redirect
    assert_redirected_to forum_topic_path(@forum, @topic)
    assert_nil @topic.locked_at
  end
end
