# frozen_string_literal: true

class PasswordsController < Devise::PasswordsController
  def create
    flash[:notice] = 'A password reset message will be sent to that email, if it exists.'
    PasswordResetJob.perform_later(resource_params.to_json)
    respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
  end
end
