# frozen_string_literal: true

FactoryBot.define do
  factory :poll_option do
    label { ["Option #{rand(1000)}"] }
  end
end
