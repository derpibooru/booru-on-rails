# frozen_string_literal: true

class Admin::Donations::UsersController < ApplicationController
  before_action :check_auth
  before_action :load_user

  def show
    @title = "Donations: #{@user.name}"
    @donations = Donation.where(user: @user)
    @donation = Donation.new
  end

  private

  def check_auth
    authorize! :manage, User
  end

  def load_user
    @user = User.find(params[:id])
  end
end
