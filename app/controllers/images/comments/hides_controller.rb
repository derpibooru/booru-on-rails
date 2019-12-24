# frozen_string_literal: true

class Images::Comments::HidesController < ApplicationController
  before_action :load_image
  before_action :load_comment
  before_action :check_auth

  def create
    ReportableHider.new(@comment, user: current_user, reason: params[:deletion_reason]).save
    HidableLogger.log(@comment, 'Deleted', current_user.name, params[:deletion_reason])

    flash[:notice] = t('comments.destroy.soft_removed')

    redirect_to image_path(@image, anchor: "comment_#{@comment.id}")
  end

  def destroy
    Unhider.new(@comment).save
    HidableLogger.log(@comment, 'Restored', current_user.name)

    respond_to do |format|
      format.html { redirect_to image_path(@image, anchor: "comment_#{@comment.id}") }
      format.json { render json: :ok }
    end
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def load_comment
    @comment = @image.comments.find(params[:comment_id])
  end

  def check_auth
    authorize! :hide, @comment
  end
end
