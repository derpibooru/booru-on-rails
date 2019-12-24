# frozen_string_literal: true

class TopicUnhider < Unhider
  def after_save
    @component.forum.increment!(:topic_count)
    @component.forum.increment!(:post_count, @component.posts.where(hidden_from_users: false).count)
    @component.forum.refresh_last_post!
  end
end
