# frozen_string_literal: true

class Images::DescriptionLocksController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def create
    @image.update(description_editing_allowed: false)

    flash[:notice] = t('images.toggle_description_lock.locked')
    HidableLogger.log(@image, 'Description editing locked', current_user.name)
    redirect_to short_image_path(@image)
  end

  def destroy
    @image.update(description_editing_allowed: true)

    flash[:notice] = t('images.toggle_description_lock.unlocked')
    HidableLogger.log(@image, 'Description editing unlocked', current_user.name)
    redirect_to short_image_path(@image)
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def check_auth
    authorize! :manage, @image
  end
end
