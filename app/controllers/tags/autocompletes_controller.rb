# frozen_string_literal: true

class Tags::AutocompletesController < ApplicationController
  skip_authorization_check

  def show
    @query = params[:term].downcase if params[:term] && params[:term].size > 2

    if @query
      search = Tag.fancy_search(size: 5) do |s|
        # Perform wildcard term search over entire tag name.
        s.add_filter(bool: { should: [
          { prefix: { name: @query } },
          { prefix: { name_in_namespace: @query } }
        ] })
        s.add_sort images: :desc
      end
      @tags = search.records.to_a.compact.uniq(&:name).map do |t|
        # Since we're skipping the DB, do a manual URI encode.
        tag_naim = t.name
        tag_naim.force_encoding('utf-8')
        tag_naim = CGI.unescape(tag_naim)
        { label: "#{tag_naim} (#{t.images_count})", value: tag_naim }
      end
    else
      @tags = []
    end

    respond_to do |format|
      format.json { render json: @tags, root: false }
    end
  end
end
