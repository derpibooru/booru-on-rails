# frozen_string_literal: true

class DuplicateReports::AcceptReversesController < ApplicationController
  before_action :load_report
  before_action :check_auth

  # Find report in reverse direction or create one, reject original report if it works
  def create
    reverse_report = @duplicate_report.duplicate_of_image.duplicate_reports.find_by(duplicate_of_image: @duplicate_report.image)
    reverse_report ||= DuplicateReport.create! image: @duplicate_report.duplicate_of_image, duplicate_of_image: @duplicate_report.image,
                                               reason: @duplicate_report.reason + "\n(Reverse accepted)", user: @duplicate_report.user

    if reverse_report.accept!(current_user)
      flash[:notice] = t('duplicate_reports.accept_reverse_success')
      @duplicate_report.reject!(current_user)
    else
      flash[:error] = reverse_report.errors.full_messages.first || t('duplicate_reports.processing_error')
      reverse_report.destroy
    end

    redirect_back
  end

  private

  def load_report
    @duplicate_report = DuplicateReport.find(params[:duplicate_report_id])
  end

  def check_auth
    authorize! :accept, @duplicate_report
  end
end
