# frozen_string_literal: true

class Images::HashesController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def destroy
    @image.update(image_orig_sha512_hash: nil)

    HidableLogger.log(@image, 'Hashes cleared', current_user.name)

    flash[:notice] = t('images.clear_hash.success')

    redirect_to short_image_path(@image)
  end

  private

  def load_image
    @image = Image.find_by!(id: params[:image_id])
  end

  def check_auth
    authorize! :hide, @image
  end
end
