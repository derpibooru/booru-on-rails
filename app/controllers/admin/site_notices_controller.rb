# frozen_string_literal: true

class Admin::SiteNoticesController < ApplicationController
  before_action :check_auth
  before_action :set_site_notice, only: [:show, :edit, :update, :destroy]

  # GET /admin/site_notices
  def index
    @title = 'Admin - Site Notices'
    @site_notices = SiteNotice.order(start_date: :desc).page(params[:page]).per(25)
  end

  # GET /admin/site_notices/1
  # TODO: This page doesn't do anything right now. Probably safe to remove
  def show
    @title = "Site Notice: #{@site_notice.title}"
  end

  # GET /admin/site_notices/new
  def new
    @title = 'New Site Notice'
    @site_notice = SiteNotice.new
  end

  # GET /admin/site_notices/1/edit
  def edit
    @title = "Editing Site Notice: #{@site_notice.title}"
  end

  # POST /admin/site_notices
  def create
    @site_notice = SiteNotice.new(site_notice_params)
    @site_notice.user = current_user

    if @site_notice.save
      redirect_to admin_site_notices_path, notice: 'Site notice was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /admin/site_notices/1
  def update
    if @site_notice.update(site_notice_params)
      redirect_to admin_site_notices_path, notice: 'Site notice was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /admin/site_notices/1
  def destroy
    @site_notice.destroy
    redirect_to admin_site_notices_url
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_site_notice
    @site_notice = SiteNotice.find(params[:id])
  end

  def check_auth
    authorize! :manage, SiteNotice
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def site_notice_params
    params.require(:site_notice).permit(:title, :text, :link, :link_text, :start, :finish, :live)
  end
end
