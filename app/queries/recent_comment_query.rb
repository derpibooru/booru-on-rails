# frozen_string_literal: true

class RecentCommentQuery
  def self.limit(count)
    Comment.joins(:image)
           .where('images.hidden_from_users': false)
           .where('comments.hidden_from_users': false)
           .order(created_at: :desc)
           .preload(:image, :user)
           .limit(count)
  end
end
