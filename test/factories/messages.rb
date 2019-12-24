# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    conversation
    from { create(:user) }
    body { 'Hi' }
  end
end
