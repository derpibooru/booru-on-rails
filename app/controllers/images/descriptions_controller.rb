# frozen_string_literal: true

class Images::DescriptionsController < ApplicationController
  before_action :filter_banned_users
  before_action :load_image
  before_action :check_auth

  def update
    if @image.description_editing_allowed || can?(:manage, Image)
      @image.update(description: params[:description])
      DescriptionChangeLogger.log(@image, current_user)
    end

    render partial: 'images/description', layout: false
  end

  private

  def load_image
    @image = Image.find_by!(id: params[:image_id], hidden_from_users: false)
  end

  def check_auth
    authorize! :update, @image
  end
end
