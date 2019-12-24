# frozen_string_literal: true

require 'image_loader'

class Images::WatchedsController < ApplicationController
  before_action :require_user
  before_action :setup_pagination_and_tags

  skip_authorization_check

  def show
    @search = ImageLoader.new(default_image_filter_options).search('my:watched')
    @images = @search.records

    respond_to do |format|
      format.html { redirect_to search_path(q: 'my:watched') }
      format.rss  { render layout: false }
      format.json { render json: { images: @images.map(&:as_json), interactions: (@interactions || []) } }
    end
  end
end
