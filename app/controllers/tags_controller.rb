# frozen_string_literal: true

require 'image_loader'

class TagsController < ApplicationController
  before_action :load_tag, only: [:show]

  skip_authorization_check

  def index
    setup_pagination_and_tags

    @title = 'Tags'
    @query = (params[:tq].presence || '*').downcase
    @per_page = 250
    @options = { per_page: @per_page, page: @page_num }
    @sort = [{ images: :desc }, { name: :asc }]

    begin
      @tags = Tag.fancy_search(@options.merge(query: @query, sorts: @sort)).records
    rescue SearchParsingError => ex
      @error = ex.message
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest
      @error = 'Processing error. Please report this query if this error persists.'
    end

    respond_to do |format|
      format.html { render }
      format.json { render json: @tags }
    end
  end

  def show
    if @tag.aliased_tag
      respond_to do |format|
        format.html { redirect_to @tag.aliased_tag, notice: "This tag ('#{@tag.name}') has been aliased to the tag '#{@tag.aliased_tag.name}'" }
        format.json { redirect_to url_for(@tag.aliased_tag) + '.json' }
      end
      return
    end
    setup_pagination_and_tags
    @title = "#{@tag.name} - Tags"
    loader = ImageLoader.new(default_image_filter_options)
    @search = loader.tag(@tag)
    @images = @search.records(includes: :tags)
    # enable bottom search form
    params[:q] = @search_query = escape_tag(@tag.name)

    @interactions = ImageQuery.interactions(@images.map(&:id), current_user.id) if current_user
    @ignoredtaglist = [@tag]
    @dnp_entries = @tag.dnp_entries.where(aasm_state: 'listed')
    respond_to do |format|
      format.html { render }
      format.json do
        render json: {
          tag:          @tag,
          aliases:      @tag.aliases.map(&:name),
          dnp_entries:  @dnp_entries.map(&:as_json),
          images:       @images.map(&:as_json),
          interactions: (@interactions || [])
        }
      end
    end
  end

  private

  def load_tag
    @tag = Tag.find_by_slug_or_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @tag
  end

  def escape_tag(name)
    name = name.squish.downcase

    if name.include?('(') || name.include?(')')
      # \ * ? " should be escaped:
      name = name.gsub(/[\\*?"]/, '\\' => '\\\\', '*' => '\*', '?' => '\?', '"' => '\"')
      # wrap in quotes or the parser can choke on parens:
      name = "\"#{name}\""
    else
      # \ * ? - ! " all must be escaped:
      name = name.gsub(/(\A-|\A!|[\\*?"])/, '\\' => '\\\\', '*' => '\*', '?' => '\?', '-' => '\-', '!' => '\!', '"' => '\"')
    end

    name
  end
end
