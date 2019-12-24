# frozen_string_literal: true

class Profiles::FpHistoriesController < ApplicationController
  before_action :load_user
  before_action :check_auth

  # GET /profiles/:profile_id/fp_history
  def show
    @title = "#{@user.name}'s Fingerprint History"
  end

  private

  def load_user
    @user = User.find_by_slug_or_id(params[:profile_id])
    raise ActiveRecord::RecordNotFound unless @user
  end

  def check_auth
    authorize! :mod_read, User
  end
end
