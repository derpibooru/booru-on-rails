# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { generate(:name) }
    email { "#{SecureRandom.hex(6)}@example.com" }
    password { 'testtest' }
    password_confirmation { 'testtest' }
    role { 'user' }
    current_sign_in_ip { '123.123.123.123' }
    factory :admin do
      role { 'admin' }
    end
    factory :moderator do
      role { 'moderator' }
    end
    factory :assistant do
      role { 'assistant' }
      factory :dupe_assistant do
        transient do
          roles { [[:moderator, DuplicateReport]] }
        end
      end
      factory :image_assistant do
        transient do
          roles { [[:moderator, Image], [:moderator, DuplicateReport]] }
        end
      end
      factory :comment_assistant do
        transient do
          roles { [[:moderator, Comment]] }
        end
      end
      factory :tag_assistant do
        transient do
          roles { [[:moderator, Tag]] }
        end
      end
    end
    after(:create) do |u, evaluator|
      evaluator.roles.each do |role|
        u.add_role(*role)
      end
    end
  end
end
