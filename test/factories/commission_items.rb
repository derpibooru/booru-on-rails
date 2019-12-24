# frozen_string_literal: true

FactoryBot.define do
  factory :commission_item do
    commission { create(:commission) }
    item_type { 'Sketch' }
    description { 'Cute pony sketch' }
    base_price { '10' }
    add_ons { 'Boops are always free' }
    example_image { create(:image) }
  end
end
