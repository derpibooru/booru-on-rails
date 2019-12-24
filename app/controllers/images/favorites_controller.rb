# frozen_string_literal: true

class Images::FavoritesController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def index
    respond_to do |format|
      format.html { render partial: 'images/image_favouriters', locals: { image: @image } }
      format.json { render json: @image.faves.map(&:user_id) }
    end
  end

  private

  def load_image
    @image = Image.includes(faves: :user).find(params[:image_id])
  end

  def check_auth
    authorize! :read, @image
  end
end
