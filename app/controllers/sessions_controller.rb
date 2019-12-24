# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  def create
    if !params[:user][:otp_attempt]
      login_target = User.find_for_authentication(email: params[:user][:email])
      login_target = nil if login_target && !login_target.valid_password?(params[:user][:password])

      if login_target&.otp_required_for_login
        redirect_to '/users/sign_in', flash: {
          error:         'Please enter your two-factor auth code',
          otp_challenge: true,
          email:         params[:user][:email].presence,
          password:      params[:user][:password].presence,
          remember_me:   params[:user][:remember_me].presence
        }

        return
      end
    end

    super
  end
end
