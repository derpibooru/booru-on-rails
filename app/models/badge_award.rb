# frozen_string_literal: true

class BadgeAward < ApplicationRecord
  resourcify

  scope :creation_order, -> { order('created_at ASC') }
  # Using this scope causes custom badges to be listed first
  scope :priority_first, -> { joins(:badge).order('badges.priority DESC, badge_awards.created_at ASC') }

  # Relations
  belongs_to :user, optional: true
  belongs_to :badge, optional: true
  belongs_to :awarded_by, class_name: 'User', inverse_of: :awards_given, optional: true

  def as_json(*)
    badge.as_json.merge(id: id, label: label, awarded_on: awarded_on)
  end
end
