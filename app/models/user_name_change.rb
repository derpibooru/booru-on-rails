# frozen_string_literal: true

class UserNameChange < ApplicationRecord
  belongs_to :user, optional: true
end
