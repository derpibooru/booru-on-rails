# frozen_string_literal: true

class Images::PreviewsController < ApplicationController
  skip_authorization_check

  def create
    @image = Image.new(description: params[:body])

    render partial: 'images/description'
  end
end
