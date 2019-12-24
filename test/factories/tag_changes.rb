# frozen_string_literal: true

FactoryBot.define do
  factory :tag_change do
    image { create(:image_skips_validation) }
    added { true }
    tag
    ip { '127.0.0.1' }
    user_agent { 'Not IE10 (Legit)' }
    referrer { 'https://derpibooru.org/blah' }
    fingerprint { 'c1836832948' }
    factory :tag_change_as_user do
      user
    end
  end
end
