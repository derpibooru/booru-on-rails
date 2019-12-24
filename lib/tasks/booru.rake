# frozen_string_literal: true

namespace :booru do
  namespace :forums do
    desc 'Build topic positions'
    task build_topic_positions: :environment do
      count = Topic.count
      c = 0
      Topic.each do |topic|
        puts "Building topic positions for topic '#{topic.title}' (#{c} of #{count})"
        i = 0
        c += 1
        topic.posts.order(created_at: :asc).select([:id, :topic_position]).each do |post|
          puts "Setting #{post.id} to #{i}"
          post.set(topic_position: i)
          i += 1
        end
      end
    end

    desc 'Build topic post counts'
    task build_topic_post_counts: :environment do
      Topic.each do |topic|
        topic.set(post_count: topic.posts.where(hidden_from_users: false).count)
      end
      Forum.each do |forum|
        forum.set(post_count: forum.topics.where(hidden_from_users: false).sum(:post_count))
        forum.set(topic_count: forum.topics.where(hidden_from_users: false).size)
      end
    end
  end
end
