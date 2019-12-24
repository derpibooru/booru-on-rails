# frozen_string_literal: true

class DuplicateReports::AcceptsController < ApplicationController
  before_action :load_report
  before_action :check_auth

  def create
    if @duplicate_report.accept!(current_user)
      flash[:notice] = t('duplicate_reports.accept_success')
    else
      flash[:error] = @duplicate_report.errors.full_messages.first || t('duplicate_reports.processing_error')
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
