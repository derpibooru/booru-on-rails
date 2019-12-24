# frozen_string_literal: true

class CommentDestroyer
  def initialize(comment)
    @comment = comment
  end

  def save
    @comment.update(body: '', destroyed_content: true)
    @comment.versions.destroy_all
    @comment.image.decrement!(:comments_count)

    # Kick off index updates
    @comment.update_index
    @comment.image.update_index

    true
  end
end
