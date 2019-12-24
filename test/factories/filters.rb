# frozen_string_literal: true

FactoryBot.define do
  factory :filter do
    name { 'Some Filter' }
    description { 'Some description' }
    factory :filter_default do
      name { 'Default' }
      system { true }
      hidden_tag_list { 'explicit' }
    end
    factory :filter_everything do
      name { 'Everything' }
      system { true }
    end
    factory :filter_porn_only do
      name { 'Clop mode' }
      hidden_tag_list { 'safe' }
      hidden_complex_str { '-explicit AND -questionable' }
    end
    factory :user_filter do
      name { "Users' Default" }
      user
      hidden_tag_list { 'explicit,semi-grimdark,grimdark,grotesque' }
      spoilered_tag_list { 'questionable,suggestive' }
    end
  end
end
