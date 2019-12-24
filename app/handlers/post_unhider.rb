# frozen_string_literal: true

class PostUnhider < Unhider
  def after_save
    @component.topic.forum.increment!(:post_count)
    @component.topic.increment!(:post_count)
    @component.user.increment!(:forum_posts_count) if @component.user
    @component.topic.refresh_last_post!
    @component.topic.forum.refresh_last_post!
  end
end
