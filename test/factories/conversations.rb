# frozen_string_literal: true

FactoryBot.define do
  factory :conversation do
    title { 'hi' }
    from { create(:user) }
    to { create(:user) }
    last_message_at { Time.zone.now }

    factory :conversation_with_messages do
      after(:create) do |conversation|
        create(:message, conversation: conversation, from: conversation.from)
        create(:message, conversation: conversation, from: conversation.to)
      end
    end
  end
end
