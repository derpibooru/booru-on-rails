# frozen_string_literal: true

class Admin::ReportsController < ApplicationController
  include ReportsHelper
  before_action :check_auth
  before_action :load_report, only: [:show]

  def index
    @title = 'Admin - Reports'
    setup_pagination_and_tags

    if params[:rq] && params[:rq].present?
      @reports = Report.fancy_search(page: @page_num, per_page: @per_page, query: params[:rq]) do |search|
        search.add_sort open: :desc
        search.add_sort state: :desc
        search.add_sort created_at: :desc
      end.records
    else
      @reports = Report.fancy_search(page: @page_num, per_page: @per_page) do |search|
        search.add_query(bool: { should: [
          { term: { open: 'false' } },
          { bool: { must: [
            { term: { open: 'true' } },
            { bool: { must_not: { term: { admin_id: current_user.id.to_s } } } }
          ] } }
        ] })
        search.add_sort open: :desc
        search.add_sort state: :desc
        search.add_sort created_at: :desc
      end.records
      @my_reports = current_user.managed_reports.where(open: true).order(created_at: :desc).for_view
    end
  end

  def show
    @title = "Report: #{reported_thing @report.reportable}"
  end

  private

  def check_auth
    authorize! :manage, Report
  end

  def load_report
    @report = Report.find(params[:id])
  end
end
