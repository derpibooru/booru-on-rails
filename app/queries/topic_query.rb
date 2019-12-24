# frozen_string_literal: true

class TopicQuery
  def self.recent(count)
    Topic.joins(:forum)
         .where('forums.access_level': :normal)
         .where('topics.hidden_from_users': false)
         .where("topics.title !~ 'NSFW'")
         .order(last_replied_to_at: :desc)
         .preload(:forum, last_post: :user)
         .limit(count)
  end
end
