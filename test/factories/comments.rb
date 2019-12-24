# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    image { create(:image_skips_validation) }
    body { 'This is an example post' }
    anonymous { false }
    ip { '127.0.0.1' }
    user_agent { 'Not IE10 (Legit)' }
    referrer { 'https://derpibooru.org/blah' }
    fingerprint { 'c1836832948' }
    factory :comment_as_anon do
      user
      anonymous { true }
    end
    factory :comment_as_user do
      user
      anonymous { false }
    end
  end
end
