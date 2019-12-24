# frozen_string_literal: true

class UnlockAccountJob < ApplicationJob
  queue_as :high

  def perform(params)
    resource_params = JSON.parse(params)
    User.send_unlock_instructions(resource_params)
  end
end
