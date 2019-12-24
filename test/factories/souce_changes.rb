# frozen_string_literal: true

FactoryBot.define do
  factory :source_change do
    image { create(:image_skips_validation) }
    initial { false }
    new_value { 'http://butts.com' }
    ip { '127.0.0.1' }
    user_agent { 'Not IE10 (Legit)' }
    referrer { 'https://derpibooru.org/blah' }
    fingerprint { 'c1836832948' }
    factory :source_change_as_user do
      user
    end
  end
end
