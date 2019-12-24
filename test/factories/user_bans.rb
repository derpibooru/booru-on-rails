# frozen_string_literal: true

FactoryBot.define do
  factory :user_ban do
    user
    reason { 'Things happened.' }
    banning_user { create(:moderator) }
    # 1-hour ban.
    valid_until { 1.hour.from_now }
    factory :expired_user_ban do
      valid_until { 1.hour.ago }
    end
  end
end
