# frozen_string_literal: true

class SpoilerTypesController < ApplicationController
  before_action :require_user

  skip_authorization_check

  def update
    current_user.set_spoiler!(params[:id])
    redirect_back flash: { notice: "Spoiler type is now #{current_user.spoiler_type}!" }
  end
end
