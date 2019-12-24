# frozen_string_literal: true

FactoryBot.define do
  factory :poll do
    title { "Poll #{rand(1000)}" }
    self.until { 'a week from now' }
    vote_method { 'single' }
    options { build_list :poll_option, 3 }
    topic
  end
end
