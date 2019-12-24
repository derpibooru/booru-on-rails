# frozen_string_literal: true

class Api::V2::UsersController < Api::V2::ApiController
  skip_authorization_check

  def current
    respond_with current_user
  end

  def show
    @user = User.find_by(id: params[:id])
    respond_with @user
  end

  def fetch_many
    @users = User.where(id: params[:ids])
    respond_with @users
  end
end
