# frozen_string_literal: true

class Images::FilesController < ApplicationController
  include ImageUpload

  before_action :load_image
  before_action :check_auth

  def update
    scraped_url = scraped_image_url

    if scraped_url
      @image.remote_image_url = scraped_url
    elsif params[:image].present?
      @image.image = params[:image]
    end

    @image.updated_at = Time.zone.now
    @image.thumbnails_generated = false
    @image.processed = false
    @image.save!
    @image.update_index

    HidableLogger.log(@image, 'Image replaced', current_user.name)

    redirect_to short_image_path(@image)
  end

  private

  def load_image
    @image = Image.find_by!(id: params[:image_id])
  end

  def check_auth
    authorize! :manage, @image
  end
end
