# frozen_string_literal: true

class Profiles::AliasesController < ApplicationController
  before_action :load_user
  before_action :check_auth

  # GET /profiles/:profile_id/aliases
  def index
    @title = "#{@user.name}'s Aliases"
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
