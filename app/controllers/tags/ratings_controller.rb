# frozen_string_literal: true

class Tags::RatingsController < ApplicationController
  skip_authorization_check

  def index
    @title = 'Rating Tags'
    @rating_tags = Tag.rating_tags.order(name: :asc)
    respond_to do |format|
      format.html { render }
      format.json { render json: @rating_tags }
    end
  end
end
