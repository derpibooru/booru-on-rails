# frozen_string_literal: true

class Images::ScratchpadsController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def edit
    @title = "Editing Scratchpad: Image ##{@image.id}"
  end

  def update
    @image.update(scratchpad: params[:scratchpad])
    redirect_to image_path(@image)
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def check_auth
    authorize! :edit_scratchpad, @image
  end
end
