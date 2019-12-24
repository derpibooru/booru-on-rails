# frozen_string_literal: true

class Galleries::ImagesController < ApplicationController
  before_action :load_gallery
  before_action :load_image
  before_action :check_auth

  def create
    @gallery.add @image

    respond_to do |format|
      format.html { redirect_back notice: 'Added image successfully' }
      format.json { render json: {} }
    end
  end

  def destroy
    @gallery.remove @image

    respond_to do |format|
      format.html { redirect_back notice: 'Removed image successfully' }
      format.json { render json: {} }
    end
  end

  private

  def load_gallery
    @gallery = Gallery.find(params[:gallery_id])
  end

  def load_image
    @image = Image.find(params[:id])
  end

  def check_auth
    authorize! :edit, @gallery
  end
end
