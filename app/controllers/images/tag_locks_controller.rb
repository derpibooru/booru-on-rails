# frozen_string_literal: true

class Images::TagLocksController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def create
    @image.update(tag_editing_allowed: false)

    flash[:notice] = t('images.toggle_tags_lock.locked')
    HidableLogger.log(@image, 'Tag editing locked', current_user.name)
    redirect_to short_image_path(@image)
  end

  def destroy
    @image.update(tag_editing_allowed: true)

    flash[:notice] = t('images.toggle_tags_lock.unlocked')
    HidableLogger.log(@image, 'Tag editing unlocked', current_user.name)
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
