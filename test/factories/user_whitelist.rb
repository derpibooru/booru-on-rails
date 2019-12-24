# frozen_string_literal: true

FactoryBot.define do
  factory :user_whitelist do
    user
    reason { 'Best user' }
  end
end
