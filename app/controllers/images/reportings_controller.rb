# frozen_string_literal: true

class Images::ReportingsController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def show
    @dupe_reports = DuplicateReport.includes(:image, :duplicate_of_image).where('image_id = ? OR duplicate_of_image_id = ?', @image.id, @image.id)
    render partial: 'images/image_reporting', locals: { image: @image }
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def check_auth
    authorize! :read, @image
  end
end
