# frozen_string_literal: true

class PasswordResetJob < ApplicationJob
  queue_as :high

  def perform(params)
    resource_params = JSON.parse(params)
    User.send_reset_password_instructions(resource_params)
  end
end
