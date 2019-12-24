# frozen_string_literal: true

class Images::HidesController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def create
    ImageHider.new(@image, user: current_user, reason: params[:deletion_reason]).save
    HidableLogger.log(@image, 'Deleted', current_user.name, params[:deletion_reason])

    redirect_to image_path(@image), notice: t('images.destroy.success', id: @image.id)
  end

  def update
    if params[:deletion_reason].blank?
      flash[:error] = t('images.errors.blank_deletion_reason')
      respond_to do |format|
        format.html { redirect_to image_path(@image) }
        format.json { head :error }
      end
      return
    end

    @image.update_columns(deletion_reason: params[:deletion_reason])

    HideReasonChangeLogger.log(@image, current_user)

    notice = t('images.change_hide_reason.success')

    respond_to do |format|
      format.html { redirect_to image_path(@image), notice: notice }
      format.json { head :ok }
    end
  end

  # TODO: this is a mess
  def destroy
    if @image.duplicate_id
      @dup_image = Image.find_by id: @image.duplicate_id
      dr = @image.duplicate_reports.find_by(duplicate_of_image_id: @dup_image.id) rescue nil
      if dr
        dr.reject!(current_user)
      else
        # manually set as non-dupe
        @image.duplicate_id = nil
        ImageUnhider.new(@image).save
      end
      # restore featured_on to this image if dupe had it set
      if !@dup_image.featured_on.nil?
        @image.featured_on = @dup_image.featured_on
        @image.save!
        @dup_image.featured_on = nil
        @dup_image.save!
      end
    else
      ImageUnhider.new(@image).save
    end

    HidableLogger.log(@image, 'Restored', current_user.name)

    respond_to do |format|
      format.html { redirect_to image_path(@image) }
      format.json { head :ok }
    end
  end

  private

  def load_image
    @image = Image.find_by!(id: params[:image_id], destroyed_content: false)
  end

  def check_auth
    authorize! :hide, @image
  end
end
