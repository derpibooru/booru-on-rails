# frozen_string_literal: true

FactoryBot.define do
  factory :subnet_ban do
    reason { 'Things happened.' }
    # 1-hour ban.
    valid_until { 1.hour.from_now }
    specification { '192.168.0.1' }
    banning_user { create(:moderator) }
    factory :expired_subnet_ban do
      valid_until { 1.hour.ago }
    end
  end
end
