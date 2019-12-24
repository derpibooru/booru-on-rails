# frozen_string_literal: true

class Images::RepairsController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def create
    HidableLogger.log(@image, 'Repair attempted', current_user.name)

    if ImageRepairer.new(@image).repair!
      respond_to do |format|
        format.html { redirect_to(image_path(@image), notice: t('images.repair.success')) }
        format.json { head :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to(image_path(@image), notice: t('images.repair.failure')) }
        format.json { head :ok }
      end
    end
  end

  private

  def load_image
    @image = Image.find_by!(id: params[:image_id], destroyed_content: false)
  end

  def check_auth
    authorize! :repair, @image
  end
end
