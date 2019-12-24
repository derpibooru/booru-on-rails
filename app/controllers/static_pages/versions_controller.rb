# frozen_string_literal: true

class StaticPages::VersionsController < ApplicationController
  before_action :set_static_page, only: [:index]
  skip_authorization_check

  # GET /static_pages/1/versions
  def index
    @title = "Revision History: #{@static_page.title}"
    @versions = @static_page.versions.includes(:user).order(created_at: :desc)
    @versions = @versions.zip([*@versions[1..-1], nil])
  end

  private

  def set_static_page
    @static_page = StaticPage.find_by!(slug: params[:static_page_id])
  end
end
