# frozen_string_literal: true

class Tags::TagChangesController < ApplicationController
  before_action :set_state
  before_action :load_tag
  before_action :load_tag_changes

  skip_authorization_check

  respond_to :html, :json

  def index
    @title = "Tag Changes: #{@tag.name}"
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

  def load_tag
    @tag = Tag.find_by!(slug: params[:tag_id])
  end

  def load_tag_changes
    @tag_changes = TagChange.where(tag_id: @tag.id).includes(:image)
    @tag_changes = @tag_changes.where(added: @state) unless @state.nil?
    @tag_changes = @tag_changes.page(params[:page]).per(20)

    @tag_change
  end
end
