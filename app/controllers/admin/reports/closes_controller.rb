# frozen_string_literal: true

class Admin::Reports::ClosesController < ApplicationController
  before_action :check_auth
  before_action :load_report

  def create
    @report.state = 'closed'
    @report.open = false
    @report.admin = current_user
    @report.save!
    @report.update_index
    ReportLogger.log(@report, 'Closed')

    redirect_back notice: 'Successfully closed report'
  end

  private

  def check_auth
    authorize! :manage, Report
  end

  def load_report
    @report = Report.find(params[:report_id])
  end
end
