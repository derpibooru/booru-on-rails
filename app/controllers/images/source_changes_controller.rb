# frozen_string_literal: true

class Images::SourceChangesController < ApplicationController
  before_action :load_image
  before_action :load_source_changes

  skip_authorization_check

  respond_to :html, :json

  def index
    @title = "Source Changes: ##{@image.id}"
    respond_with @source_changes
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def load_source_changes
    @source_changes = SourceChange.where(image: @image).includes(:image)
    @source_changes = @source_changes.page(params[:page]).per(20)
  end
end
