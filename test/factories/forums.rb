# frozen_string_literal: true

FactoryBot.define do
  factory :forum do
    name { generate(:forum_name) }
    short_name { generate(:short_forum_name) }
    topic_count { 0 }
    post_count { 0 }
    description { 'For discussing the show' }
    factory :forum_with_topics do
      transient do
        topics_count { 5 }
      end
      after(:create) do |forum, evaluator|
        FactoryBot.create_list(:topic, evaluator.topics_count, forum: forum)
      end
    end
  end
end
