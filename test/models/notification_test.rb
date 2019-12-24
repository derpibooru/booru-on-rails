# frozen_string_literal: true

require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  setup do
    @topic = create(:topic_with_posts)
    @post = @topic.posts.first
    @user = create(:user)
    @creator = create(:user)
  end

  test 'has an actor and an actor_child' do
    Notification.watch(@topic, @user)

    assert_difference('Notification.count') { immediate_notify(@topic, 'ran the tests', @post) }

    n = Notification.first
    assert_equal @topic, n.actor
    assert_equal @post, n.actor_child
  end

  test '.watch should add the user to the watcher list' do
    Notification.watch(@topic, @user)

    @topic.reload
    assert_includes @topic.subscribers, @user
  end

  test '.unwatch should remove the user from the watcher list' do
    Notification.watch(@topic, @user)
    Notification.unwatch(@topic, @user)
    assert_not_includes @topic.subscribers, @user
  end

  test '.watching? should return true if the user is watching the actor' do
    Notification.watch(@topic, @user)
    assert Notification.watching?(@topic, @user)
  end

  test '.watching? should return false if the user is not watching the actor' do
    assert_not Notification.watching?(@topic, @user)
  end

  test 'a tree should not make a sound if nobody hears it' do
    assert_no_difference('Notification.count') { immediate_notify(@topic, '*sound of tree falling*', @post) }
  end

  test 'should notify any subscribed users except the creator' do
    Notification.watch(@topic, @user)
    assert_difference('Notification.count') { immediate_notify(@topic, 'replied', @creator) }

    @user.reload
    @creator.reload
    assert_empty @creator.unread_notifications
    assert_not_empty @user.unread_notifications
  end

  test 'should not allow duplicates to form' do
    Notification.watch(@topic, @user)
    4.times { immediate_notify(@topic, 'replied', create(:user)) }
    @user.reload
    assert_equal 1, @user.unread_notifications.count
    assert_equal 1, Notification.count
  end

  test '.mark_read should remove a notification from the user' do
    Notification.watch(@topic, @user)
    immediate_notify(@topic, 'replied', @creator)
    n1 = Notification.find_by(actor: @topic)
    Notification.mark_read(n1, @user)

    @user.reload
    assert_equal 0, @user.unread_notifications.count
  end

  test '.mark_all_read should remove all notifications for an actor for a user' do
    Notification.watch(@topic, @user)
    immediate_notify(@topic, 'replied', @creator)
    Notification.mark_all_read(@topic, @user)

    @user.reload
    assert_equal 0, @user.unread_notifications.count
  end

  test 'cleanup should remove all notifications for an actor' do
    4.times { Notification.watch(@topic, create(:user)) }
    immediate_notify(@topic, 'replied', @creator)
    assert_difference('Notification.count', -1) do
      NotificationCleanupJob.perform_now(@topic.id, 'Topic')
    end
  end

  def immediate_notify(actor, action, actor_child)
    NotificationJob.perform_now(actor.id, actor.class.to_s, action, actor_child&.id, actor_child&.class&.to_s)
  end
end
