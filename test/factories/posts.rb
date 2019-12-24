# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    body { 'This is an example post' }
    topic
    anonymous { false }
    ip { '127.0.0.1' }
    user_agent { 'Not IE10 (Legit)' }
    referrer { 'https://derpibooru.org/blah' }
    fingerprint { 'c1836832948' }
    factory :post_as_anon do
      user
      anonymous { true }
    end
    factory :post_as_user do
      user
      anonymous { false }
    end
    factory :deleted_post do
      user
      hidden_from_users { true }
      deletion_reason { 'BECAUSE I CAN' }
      association :deleted_by, factory: :admin
    end
  end
end
