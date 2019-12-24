# frozen_string_literal: true

FactoryBot.define do
  factory :duplicate_report do
    reason { 'Suspected duplicate' }
    state { 'open' }
    image { create :dedupe_image_1 }
    duplicate_of_image { create :dedupe_image_2 }
  end
end
