# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    name { generate(:tag_name) }
    description { '' }
    short_description { '' }

    factory :spoiler_tag do
      description { 'This is a spoiler tag' }
      factory :season_4 do
        name { 'spoiler:s4' }
      end
    end
    factory :system do
      factory :safe do
        name { 'safe' }
        description { 'Safe for work and children.' }
      end
      factory :suggestive do
        name { 'suggestive' }
      end
      factory :questionable do
        name { 'questionable' }
      end
      factory :explicit do
        name { 'explicit' }
        description { 'Onscreen sex (even if not visible) or genital nudity' }
      end
      factory :semi_grimdark do
        name { 'semi-grimdark' }
      end
      factory :grimdark do
        name { 'grimdark' }
      end
      factory :grotesque do
        name { 'grotesque' }
      end
    end
    factory :test_tag do
      name { 'test tag' }
    end
    factory :artist_tag do
      name { 'artist:the-smiling-pony' }
    end
  end
end
