# frozen_string_literal: true

class Images::Comments::HistoriesController < ApplicationController
  before_action :load_image
  before_action :load_comment
  before_action :check_auth

  def show
    @title = "Comment History on ##{@image.id} for #{@comment.user.name}"
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def load_comment
    @comment = @image.comments.find(params[:comment_id])
  end

  def check_auth
    authorize! :read, @comment
  end
end
