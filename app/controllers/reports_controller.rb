# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :filter_banned_users, except: [:index]
  before_action :setup_report, only: [:new, :create]

  def index
    @reports = current_user.reports_made.order(created_at: :desc).page(params[:page]).per(20) if current_user
    @title = 'Your Reports'
    authorize! :create, Report
  end

  def new
    authorize! :create, @report
    @title = 'Create Report'
  end

  def create
    reason = params[:category].to_s
    reason += ': ' + params[:report][:reason] if params[:report][:reason].present?
    @report.reason = reason
    authorize! :create, @report
    if !captcha_verified?
      respond_to do |format|
        format.html { flash[:notice] = "Your report hasn't been accepted, please fill in the captcha"; render action: 'new' }
        format.js { render plain: 'Report not received, please fill in the captcha', layout: false }
      end
      return
    end
    # Anti report spam
    if current_user && current_user.reports_made.where(state: %w[open in_progress]).count >= 5 ||
       Report.where(ip: request.remote_ip, state: %w[open in_progress]).count >= 5
      redirect_back notice: 'Due to heavy report spam, you may not have more than 5 open reports at a time. Did you read the reporting tips?'
      return
    end
    # If we're allowed to...
    if @report.save
      @report.update_index
      NewReportLogger.log(@report)
      respond_to do |format|
        format.html { flash[:notice] = 'Your report has been received and will be checked by an administrator shortly.'; redirect_to reports_path }
        format.js { render plain: 'Report receieved', layout: false }
      end
    else
      respond_to do |format|
        format.html { flash[:notice] = "Your report hasn't been recieved."; render action: 'new' }
        format.js { render plain: "Report not receieved. #{@report.errors.to_a.join(' ')}", layout: false }
      end
    end
  end

  private

  def setup_report
    if (@reportable = find_reportable)
      @report = @reportable.reports.new(request_attributes)
    else
      respond_to do |format|
        format.html { flash[:notice] = 'Your report has no associated reportable entity and cannot be received.'; redirect_to reports_path }
        format.js { render plain: 'Report received', layout: false }
      end
    end
  end

  def find_reportable
    reportable_class = params[:reportable_class].capitalize.safe_constantize
    return false unless reportable_class < Reportable

    query = { id: params[:reportable_id] }
    query['hidden_from_users'] = false if reportable_class.column_names.include? 'hidden_from_users'
    @reportable = reportable_class.find_by(query)
  end
end
