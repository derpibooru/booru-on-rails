# frozen_string_literal: true

FactoryBot.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end
  sequence :name do |n|
    "Jebediah #{n}"
  end
  sequence :topic_title do |n|
    "Test Topic #{n}"
  end
  sequence :forum_name do |n|
    "Test Forum #{n}"
  end
  sequence :short_forum_name do |n|
    "testforum#{('aa'..'zz').to_a[n]}"
  end
  sequence :tag_name do |n|
    "tag#{n}"
  end
end
