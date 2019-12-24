# frozen_string_literal: true

class ChangelogsController < ApplicationController
  skip_authorization_check

  def show
    @title   = 'Changelog'
    @changes = ChangelogPresenter.new

    respond_to do |format|
      format.html
      format.json { render json: @changes.as_json }
    end
  end
end
