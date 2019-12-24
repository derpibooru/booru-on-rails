# frozen_string_literal: true

class DuplicateReports::ClaimsController < ApplicationController
  before_action :load_report
  before_action :check_auth

  def create
    authorize! :claim, @duplicate_report
    @duplicate_report.claim!(current_user)
    flash[:notice] = t('duplicate_reports.claim_success')
    redirect_back
  end

  private

  def load_report
    @duplicate_report = DuplicateReport.find(params[:duplicate_report_id])
  end

  def check_auth
    authorize! :claim, @duplicate_report
  end
end
