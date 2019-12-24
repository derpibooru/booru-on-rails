# frozen_string_literal: true

FactoryBot.define do
  factory :livestream_channel do
    title { 'Spittfireart' }
    short_name { 'spittfireart' }
    is_live { false }
    viewers { 0 }
    viewer_minutes_today { 0 }
    viewer_minutes_thisweek { 0 }
    viewer_minutes_thismonth { 0 }
    total_viewer_minutes { 0 }
  end
end
