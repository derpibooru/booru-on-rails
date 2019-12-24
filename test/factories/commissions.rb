# frozen_string_literal: true

FactoryBot.define do
  factory :commission do
    user { create(:user) }
    open { true }
    will_create { 'Weird stuff' }
    will_not_create { 'Very weird stuff' }
    information { 'I draw weird stuff' }
    contact { 'Teleportation' }
    categories { ['Canon Characters', 'Pony', 'Safe'] }
  end
end
