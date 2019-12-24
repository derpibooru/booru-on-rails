# frozen_string_literal: true

require 'booru'
require 'image_loader'
require 'tempfile'
require 'shellwords'

class SearchController < ApplicationController
  include ImageUpload

  before_action :setup_pagination_and_tags
  skip_authorization_check

  def index
    params[:q] = params[:sbq] if params[:sbq] && params[:sbq].present? # sbq is legacy, kept for old links
    params[:sbq] = nil
    set_image_filter

    @search_query = params[:q]

    # JSON API kludge
    @include_deleted = params.key?(:deleted) if params[:format] == 'json'

    if @search_query.present?
      @title = "Searching for #{@search_query}"
      if @include_deleted == :only
        @title += ' (Deleted/Merged Only)'
      elsif @include_deleted
        @title += ' (Including Deleted/Merged)'
      end

      begin
        loader = ImageLoader.new(default_image_filter_options.merge(sorts: parse_sort))
        @search = loader.search(@search_query)
      rescue SearchParsingError => ex
        @search_failed = ex
        respond_to do |format|
          format.html { render }
          format.json { render json: {}, status: :bad_request }
        end
      else
        # Rely on ES to filter out deleted images.
        begin
          if params[:random_image] && (random_image_id = find_random_image_id)
            return respond_to do |format|
              format.html { redirect_to image_path(random_image_id, scope_key) }
              format.json { render json: { id: random_image_id } }
            end
          else
            @images = @search.records(includes: [:tags, :user])
            @image_ids = @search.results.map { |h| h[:_id].to_i }
            # A small hack for detecting single tag searches and candidates for unspoilering.
            search_body = @search.search.definition[:body][:query][:bool][:filter]
            # If wildcards are present, detect the single tags (so they don't get spoilered)
            search_body += @search.search.definition[:body][:query][:bool][:must] if @search.search.definition[:body][:query][:bool][:must].is_a?(Array)
            setup_ignoredtaglist search_body
            @interactions = ImageQuery.interactions(@image_ids.compact.uniq, current_user.id) if current_user
          end
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest
          @images = nil
          @search_failed = 'Processing error. Please report this query if this error persists.'
        end
        respond_to do |format|
          format.html { render }
          format.json { render json: { search: @images.map(&:as_json), total: @search.total_count, interactions: (@interactions || []) } }
        end
      end
    else
      @title = 'Search'
      respond_to do |format|
        format.html { render }
        format.json { head :ok }
      end
    end
  end

  def reverse
    @title = 'Reverse Search'
    if request.post? || params[:scraper_url].present?
      data = nil

      scraped_url = scraped_image_url
      if scraped_url
        data = Booru::Scraper.fetch_image(scraped_url)
      elsif params[:image].present?
        data = params[:image].read
      else
        flash[:error] = 'We could not find an image at the URL you provided'
        redirect_to search_reverse_path
        return
      end

      if data
        t = Tempfile.new.tap(&:binmode)
        t.write data
        t.close

        begin
          fixed = Booru::Uploads::Mime.format_for(t.path)
          preview = fixed.preview
          intensities = ImageIntensities.file(preview.file.path)
        rescue StandardError
          flash[:error] = 'The image you uploaded could not be analyzed!'
          redirect_to search_reverse_path
          return
        end

        dist = params[:fuzziness].to_f rescue 0.25
        dist = 0.1 if dist < 0.1
        dist = 5.0 if dist > 5.0
        @matches = ImageQuery.duplicates(intensities, dist)
      else
        @matches = nil
      end

      respond_to do |format|
        format.html
        format.json { render json: { search: @matches.map(&:as_json), total: @matches.count } }
      end
    end
  end

  def syntax
    @title = 'Search syntax documentation'
    respond_to do |format|
      format.html { render }
      format.json { head :ok }
    end
  end

  private

  def find_random_image_id
    loader = ImageLoader.new(default_image_filter_options.merge(sample: true))
    @search = loader.search(@search_query)
    @search.results.empty? ? false : @search.results[0].id
  end

  # TODO: Clean up this mess of rescues and bizarre logic
  def setup_ignoredtaglist(search_body)
    @ignoredtaglist = search_body.map { |t| t.dig(:term, :'namespaced_tags.name') }.compact rescue []
    @ignoredtaglist = search_body.map { |t| t.dig(:bool, :must) }.compact.flatten.map { |t| t.dig(:term, :'namespaced_tags.name') } rescue [] if @ignoredtaglist.empty?
    @ignoredtaglist = @ignoredtaglist.map { |t| t.is_a?(Hash) ? t[:value] : t }
    @ignoredtaglist = Tag.includes(:implied_tags, :aliased_tag).where(name: @ignoredtaglist).map { |t| t.aliased_tag || t }
    @dnp_entries = if @ignoredtaglist[0]
      @ignoredtaglist[0].dnp_entries.where(aasm_state: 'listed')
    else
      []
    end
  end
end
