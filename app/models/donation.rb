# frozen_string_literal: true

class Donation < ApplicationRecord
  belongs_to :user, optional: true

  after_create do
    user.set_donation_badges! if user
  end

  def at
    created_at
  end

  def at=(val)
    self.created_at = Chronic.parse(val) || Time.zone.now
  end
end
