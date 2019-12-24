# frozen_string_literal: true

FactoryBot.define do
  factory :user_link do
    user
    uri { 'http://the-smiling-pony.tumblr.com' }
    tag_name { 'artist:the-smiling-pony' }
    add_attribute(:public) { true }
  end
end
