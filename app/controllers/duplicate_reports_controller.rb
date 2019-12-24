# frozen_string_literal: true

class DuplicateReportsController < ApplicationController
  before_action :filter_banned_users, only: [:create]
  before_action :require_user, only: [:create]
  before_action :load_report, except: [:index, :create]
  skip_authorization_check only: [:show]

  def index
    @title = 'Duplicate Reports'
    authorize! :manage, DuplicateReport
    states = %w[open claimed]
    valid_states = %w[open rejected accepted claimed]
    states = params[:states].split(',').map { |s| s.strip.downcase }.select { |s| valid_states.include?(s) } if params[:states]
    @duplicate_reports = DuplicateReport.includes(:image, :duplicate_of_image).where(state: states).order(created_at: :desc).page(params[:page]).per(25)
  end

  def show
    @title = "Visual Diff: #{@duplicate_report.image_id} → #{@duplicate_report.duplicate_of_image_id}"
    @image = @duplicate_report.image
    @duplicate_of_image = @duplicate_report.duplicate_of_image
  end

  def create
    authorize! :create, DuplicateReport
    @duplicate_report = DuplicateReport.new(duplicate_report_params)
    if @duplicate_report.save
      flash[:notice] = 'Your duplicate report was submitted'
    else
      flash[:alert] = @duplicate_report.errors.full_messages.first
    end
    redirect_to short_image_path(params[:image_id])
  end

  def accept
    authorize! :accept, @duplicate_report
    if @duplicate_report.accept!(current_user)
      flash[:notice] = t('duplicate_reports.accept_success')
    else
      flash[:error] = @duplicate_report.errors.full_messages.first ||
                      t('duplicate_reports.processing_error')
    end
    redirect_back
  end

  # Find report in reverse direction or create one, reject original report if it works
  def accept_reverse
    authorize! :accept, @duplicate_report
    reverse_report = @duplicate_report.duplicate_of_image.duplicate_reports.find_by(duplicate_of_image: @duplicate_report.image)
    reverse_report ||= DuplicateReport.create! image: @duplicate_report.duplicate_of_image, duplicate_of_image: @duplicate_report.image,
                                               reason: @duplicate_report.reason + "\n(Reverse accepted)", user: @duplicate_report.user
    if reverse_report.accept!(current_user)
      flash[:notice] = t('duplicate_reports.accept_reverse_success')
      @duplicate_report.reject!(current_user)
    else
      flash[:error] = reverse_report.errors.full_messages.first ||
                      t('duplicate_reports.processing_error')
      reverse_report.destroy
    end
    redirect_back
  end

  def claim
    authorize! :claim, @duplicate_report
    @duplicate_report.claim!(current_user)
    flash[:notice] = t('duplicate_reports.claim_success')
    redirect_back
  end

  def reject
    authorize! :reject, @duplicate_report
    @duplicate_report.reject!(current_user)
    flash[:notice] = t('duplicate_reports.reject_success')
    redirect_back
  end

  private

  def load_report
    @duplicate_report = DuplicateReport.find(params[:id])
  end

  def duplicate_report_params
    params.permit(:image_id, :duplicate_of_image_id, :reason).merge(user: current_user)
  end
end
