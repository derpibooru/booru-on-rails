# frozen_string_literal: true

class Admin::Users::WipesController < ApplicationController
  before_action :check_auth
  before_action :load_user

  def create
    UserWipeJob.perform_later(@user.id)
    modfeed_push('PII wipe')

    redirect_to profile_path(@user), notice: 'User PII wipe started, please verify and then deactivate account as necessary.'
  end

  private

  def check_auth
    authorize! :manage, User
  end

  def load_user
    @user = User.find_by!(slug: params[:user_id])
  end

  def modfeed_push(status)
    UserLogger.log(status, @user, current_user)
  end
end
