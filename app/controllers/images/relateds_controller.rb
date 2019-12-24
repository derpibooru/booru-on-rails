# frozen_string_literal: true

require 'image_loader'

class Images::RelatedsController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def show
    setup_pagination_and_tags

    @title = t('images.related.title', id: @image.id)

    tags_to_match = @image.tags.without_rating_tags.order(images_count: :asc).limit(10).pluck(:id).map { |tid| { term: { tag_ids: tid } } }
    favs_to_match = @image.faves.limit(11).compact.map { |f| { term: { favourited_by_user_ids: f.user_id } } }
    @mlt_search = Image.fancy_search(default_image_filter_options.except(:page)) do |search|
      search.add_query(bool: { must: [
        # primary matching source
        { bool: { should: tags_to_match[0..5], boost: 2 } },
        { bool: { should: tags_to_match[5..-1], boost: 3, minimum_should_match: '5%' } },
        # relevance fallback
        { bool: { should: favs_to_match, boost: 0.2, minimum_should_match: '5%' } }
      ] })
      search.add_filter(bool: { must_not: { term: { id: @image.id } } })
      search.add_sort _score: :desc
    end
    records = @mlt_search.records.to_a
    @images = Kaminari::PaginatableArray.new(records, limit: records.size, offset: 0, total_count: records.size)
    @interactions = ImageQuery.interactions(@images.map(&:id), current_user.id) if current_user

    respond_to do |format|
      format.html { render 'images/index' }
      format.json { render json: { images: @images.map(&:as_json), interactions: (@interactions || []) }.to_json }
    end
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def check_auth
    authorize! :read, @image
  end
end
