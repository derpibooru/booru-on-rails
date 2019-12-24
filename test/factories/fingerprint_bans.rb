# frozen_string_literal: true

FactoryBot.define do
  factory :fingerprint_ban do
    reason { 'Things happened.' }
    # 1-hour ban.
    valid_until { 1.hour.from_now }
    fingerprint { 'c1836832948' }
    banning_user { create(:moderator) }
  end
end
