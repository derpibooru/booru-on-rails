# frozen_string_literal: true

class Images::UploadersController < ApplicationController
  before_action :load_image
  before_action :check_auth

  # TODO: this can be simplified a bit
  def update
    new_name = params[:username]
    @image.anonymous = params[:anonymous]
    if new_name != (@image.user ? @image.user.name : '') # only do anything if changing
      uploader_changed = true
      if new_name.blank?
        @image.user = nil
        @image.anonymous = true
      else
        new_user = User.find_by('name = ? OR name = ?', new_name, new_name.unicode_normalize(:nfd))
        if new_user
          @image.user = new_user
        else
          @error = t('images.errors.nonexistent_user', user: new_name)
          uploader_changed = false
        end
      end
      if uploader_changed
        @image.ip = '127.0.1.1'
        @image.fingerprint = 'ffff'
      end
    end
    @image.save!
    @image.update_index
    HidableLogger.log(@image, 'Uploader changed', current_user.name)
    render partial: 'images/uploader', layout: false
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def check_auth
    authorize! :manage, @image
  end
end
