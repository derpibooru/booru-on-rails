# frozen_string_literal: true

class Profiles::DetailsController < ApplicationController
  before_action :load_user
  before_action :check_auth

  # GET /profiles/:profile_id/details
  # Get a user's mod notes
  def show
    @title = "#{@user.name}'s profile"
  end

  private

  def load_user
    @user = User.find_by_slug_or_id(params[:profile_id])
    raise ActiveRecord::RecordNotFound unless @user
  end

  def check_auth
    authorize! :manage, ModNote
  end
end
