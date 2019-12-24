# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_authorization_check

  def not_found
    @title = '404 - Page Not Found'

    respond_to do |format|
      format.html { render status: :not_found }
      format.all  { head :not_found, content_type: 'text/html' }
    end
  end
end
