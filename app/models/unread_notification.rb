# frozen_string_literal: true

class UnreadNotification < ApplicationRecord
  belongs_to :notification, optional: true
  belongs_to :user, optional: true
end
