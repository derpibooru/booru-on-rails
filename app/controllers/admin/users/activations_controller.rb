# frozen_string_literal: true

class Admin::Users::ActivationsController < ApplicationController
  before_action :check_auth
  before_action :load_user

  def destroy
    @user.soft_delete!(current_user)
    modfeed_push('Deactivated')

    redirect_to profile_path(@user), notice: 'User was deactivated.'
  end

  def create
    @user.soft_undelete!
    modfeed_push('Reactivated')

    redirect_to profile_path(@user), notice: 'User was reactivated.'
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
