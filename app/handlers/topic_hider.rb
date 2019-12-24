# frozen_string_literal: true

class TopicHider < Hider
  def after_save
    # TODO: race condition
    @component.forum.decrement!(:topic_count)
    @component.forum.decrement!(:post_count, @component.posts.where(hidden_from_users: false).count)
    @component.forum.refresh_last_post!
    Notification.mark_all_read(@component)
    Notification.async_cleanup(@component)
    $redis.lpush 'changed_threads', {
      state:    :deleted,
      topic_id: @component.id,
      reason:   @component.deletion_reason,
      marker:   @component.deleted_by.try(:name)
    }.to_json
  end
end
