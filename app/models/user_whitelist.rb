# frozen_string_literal: true

class UserWhitelist < ApplicationRecord
  belongs_to :user, optional: true

  validates :user, :reason, presence: true
  validates :user, uniqueness: true

  def username=(name)
    self.user = User.find_by(name: name)
  end

  def username
    user.try(:name)
  end
end
