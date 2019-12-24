# frozen_string_literal: true

class Galleries::RandomsController < ApplicationController
  before_action :load_gallery
  before_action :check_auth

  def show
    redirect_to search_path(q: "gallery_id:#{@gallery.id}", random_image: 'y')
  end

  private

  def load_gallery
    @gallery = Gallery.find(params[:gallery_id])
  end

  def check_auth
    authorize! :read, @gallery
  end
end
