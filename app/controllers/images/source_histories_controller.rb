# frozen_string_literal: true

require 'booru'
require 'image_loader'
require 'fileutils'
require 'retard_filter'

class Images::SourceHistoriesController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def destroy
    @image.source_changes.delete_all
    @image.source_url = ''
    @image.save

    HidableLogger.log(@image, 'Sources wiped', current_user.name)

    respond_to do |format|
      format.html { redirect_to image_path(@image.id), notice: t('images.delete_source_changes.success') }
      format.json { head :ok }
    end
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def check_auth
    authorize! :delete, SourceChange
  end
end
