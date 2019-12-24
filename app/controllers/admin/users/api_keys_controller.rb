# frozen_string_literal: true

class Admin::Users::ApiKeysController < ApplicationController
  before_action :check_auth
  before_action :load_user

  def destroy
    authorize! :mod_read, User
    @user.reset_api_token!
    modfeed_push('API key reset')

    redirect_to profile_path(@user), notice: 'User\'s API token has been successfully reset.'
  end

  private

  def check_auth
    authorize! :mod_read, User
  end

  def load_user
    @user = User.find_by!(slug: params[:user_id])
  end

  def modfeed_push(status)
    UserLogger.log(status, @user, current_user)
  end
end
