# frozen_string_literal: true

class StaffsController < ApplicationController
  skip_authorization_check

  def show
    @title = 'Staff'
    @staff = StaffPresenter.new

    respond_to do |format|
      format.html
      format.json { render json: @staff.as_json }
    end
  end
end
