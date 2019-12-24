# frozen_string_literal: true

FactoryBot.define do
  factory :gallery do
    sequence(:title) { |n| "My Awesome Gallery #{n}" }
    spoiler_warning { 'attack helicopters' }
    description { '' }
    association :creator, factory: :user

    before(:create) do |gallery, _|
      gallery.thumbnail_id = create(:image_skips_validation).id
    end
  end
end
