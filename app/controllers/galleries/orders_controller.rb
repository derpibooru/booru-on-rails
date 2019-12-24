# frozen_string_literal: true

class Galleries::OrdersController < ApplicationController
  before_action :load_gallery
  before_action :check_auth

  def update
    GalleryReorderJob.perform_later @gallery.id, params[:image_ids].map(&:to_i)

    respond_to do |format|
      format.html { redirect_back notice: 'Updating positions' }
      format.json { render json: {} }
    end
  end

  private

  def load_gallery
    @gallery = Gallery.find(params[:gallery_id])
  end

  def check_auth
    authorize! :edit, @gallery
  end
end
