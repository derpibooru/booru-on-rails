# frozen_string_literal: true

class Images::TagChangesController < ApplicationController
  before_action :load_image
  before_action :load_tag_changes

  skip_authorization_check

  respond_to :html, :json

  def index
    @title = "Tag Changes: ##{@image.id}"
    respond_with @tag_changes
  end

  private

  def set_state
    if params[:added] == '1'
      @state = true
    elsif params[:added] == '0'
      @state = false
    end
  end

  def load_image
    @image = Image.find(params[:image_id])
  end

  def load_tag_changes
    @tag_changes = TagChange.where(image: @image).includes(:image)
    @tag_changes = @tag_changes.where(added: @state) unless @state.nil?
    @tag_changes = @tag_changes.page(params[:page]).per(20)
  end
end
