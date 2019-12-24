# frozen_string_literal: true

class Admin::Reports::ClaimsController < ApplicationController
  before_action :check_auth
  before_action :load_report

  def create
    if !@report.open
      redirect_to admin_report_path(@report), notice: 'This report has already been closed.'
    elsif @report.state == 'in_progress'
      redirect_to admin_report_path(@report), notice: "This report has already been claimed by #{@report.admin.name}."
    else
      @report.state = 'in_progress'
      @report.admin = current_user
      @report.save!
      @report.update_index
      ReportLogger.log(@report, 'Claimed')
      redirect_back notice: 'Successfully marked report in progress.'
    end
  end

  def destroy
    if !@report.open
      redirect_to admin_report_path(@report), notice: 'This report has already been closed.'
    elsif @report.state != 'in_progress'
      redirect_to admin_report_path(@report), notice: 'This report is not claimed by anyone.'
    elsif @report.admin != current_user
      redirect_to admin_report_path(@report), notice: "Only #{@report.admin.name} can unclaim this report."
    else
      @report.state = 'open'
      @report.admin = nil
      @report.save!
      @report.update_index
      ReportLogger.log(@report, 'Released')
      redirect_back notice: 'Successfully unclaimed report.'
    end
  end

  private

  def check_auth
    authorize! :manage, Report
  end

  def load_report
    @report = Report.find(params[:report_id])
  end
end
