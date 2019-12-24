# frozen_string_literal: true

FactoryBot.define do
  factory :topic do
    title { generate(:topic_title) }
    post_count { 0 }
    view_count { 0 }
    sticky { false }
    last_replied_to_at { '2013-04-01 04:26:27' }
    forum
    user
    after(:create) do |topic, _evaluator|
      # Create but one post, our seed post - this shouldn't be counted
      FactoryBot.create_list(:post, 1, topic: topic, user: topic.user)
    end
    factory :sticky_topic do
      sticky { true }
    end
    factory :topic_with_posts do
      transient do
        # Multiply by 3 for actual number of posts
        posts_count { 2 }
      end
      # Make lots of posts here - no users, as anons, and as users.
      after(:create) do |topic, evaluator|
        FactoryBot.create_list(:post, evaluator.posts_count, topic: topic)
        FactoryBot.create_list(:post_as_anon, evaluator.posts_count, topic: topic)
        FactoryBot.create_list(:post_as_user, evaluator.posts_count, topic: topic)
      end
      factory :locked_topic_with_posts do
        locked_at { '2013-04-01 04:54:24' }
        lock_reason { 'Because I can' }
        association :locked_by, factory: :moderator
      end
      factory :deleted_topic_with_posts do
        hidden_from_users { true }
        deletion_reason { 'Because I can' }
        association :deleted_by, factory: :moderator
      end
      factory :topic_with_many_posts do
        transient do
          posts_count { 80 }
        end
      end
      factory :topic_with_poll do
        poll
      end
    end
  end
end
