# frozen_string_literal: true

require 'test_helper'

class Topics::HidesControllerTest < ActionController::TestCase
  setup do
    @user = create(:moderator)
    @topic = create(:topic)
    @forum = @topic.forum
  end

  test 'can be hidden' do
    sign_in @user

    post :create, params: { topic_id: @topic, forum_id: @forum, deletion_reason: 'shitpost.jpg' }

    @topic.reload
    assert @topic.hidden_from_users
    assert_equal @user, @topic.deleted_by
    assert_equal 'shitpost.jpg', @topic.deletion_reason
  end

  test 'can be restored' do
    sign_in @user

    TopicHider.new(@topic, reason: 'shitpost.jpg').save

    delete :destroy, params: { topic_id: @topic, forum_id: @forum }

    @topic.reload
    assert_not @topic.hidden_from_users
    assert_nil @topic.deleted_by
    assert_equal '', @topic.deletion_reason
  end
end
