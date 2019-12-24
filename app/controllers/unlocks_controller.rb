# frozen_string_literal: true

class UnlocksController < Devise::UnlocksController
  def create
    flash[:notice] = 'An account unlock message will be sent to that email, if it exists.'
    UnlockAccountJob.perform_later(resource_params.to_json)
    respond_with({}, location: after_sending_unlock_instructions_path_for(resource_class))
  end
end
