# frozen_string_literal: true

class ModNote < ApplicationRecord
  belongs_to :moderator, class_name: 'User', optional: true
  belongs_to :notable, polymorphic: true, optional: true

  resourcify
end
