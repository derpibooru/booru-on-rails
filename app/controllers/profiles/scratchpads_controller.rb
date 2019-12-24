# frozen_string_literal: true

class Profiles::ScratchpadsController < ApplicationController
  before_action :load_user
  before_action :check_auth

  # GET /profiles/:profile_id/scratchpad/edit
  def edit
    @title = "#{@user.name}'s Scratchpad"
  end

  # PUT /profiles/:profile_id/scratchpad
  # PATCH /profiles/:profile_id/scratchpad
  def update
    @user.scratchpad = params[:notes]
    @user.save
    redirect_to profile_path(@user.slug)
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
