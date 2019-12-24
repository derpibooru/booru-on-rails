# frozen_string_literal: true

class DuplicateReports::RejectsController < ApplicationController
  before_action :load_report
  before_action :check_auth

  def create
    authorize! :reject, @duplicate_report
    @duplicate_report.reject!(current_user)
    flash[:notice] = t('duplicate_reports.reject_success')
    redirect_back
  end

  private

  def load_report
    @duplicate_report = DuplicateReport.find(params[:duplicate_report_id])
  end

  def check_auth
    authorize! :reject, @duplicate_report
  end
end
