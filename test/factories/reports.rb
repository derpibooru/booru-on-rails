# frozen_string_literal: true

FactoryBot.define do
  factory :report do
    reason { 'Because I HATE EVERYTHING RARAR' }
    ip { '127.0.0.1' }
    user_agent { 'Not IE10 (Legit)' }
    referrer { 'https://derpibooru.org/blah' }
    fingerprint { 'c1836832948' }
    factory :report_of_image do
      reportable { create :image }
    end
    factory :report_of_comment do
      reportable { create :comment }
    end
    factory :report_of_post do
      reportable { create :post }
    end
    factory :report_of_user do
      reportable { create :user }
    end
  end
end
