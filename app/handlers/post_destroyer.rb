# frozen_string_literal: true

class PostDestroyer
  def initialize(post)
    @post = post
  end

  def save
    @post.update(body: '', destroyed_content: true)
    @post.versions.destroy_all
    @post.topic.touch

    true
  end
end
