# frozen_string_literal: true

class Admin::DonationsController < ApplicationController
  before_action :check_authorization

  def index
    @title = 'Admin - Donations'
    @donations = Donation.order('user_id ASC, created_at DESC').includes(:user).page(params[:page]).per(25)
  end

  def create
    @user = User.find_by!(id: params[:donation][:user_id])
    @donation = Donation.create!(donation_params)
    @user.update_columns(last_donation_at: @donation.at) if @user.last_donation_at.nil? || @user.last_donation_at < @donation.at
    redirect_back
  end

  private

  def check_authorization
    authorize! :manage, User
  end

  def donation_params
    params.require(:donation).permit(:user_id, :email, :amount, :note, :at)
  end
end
