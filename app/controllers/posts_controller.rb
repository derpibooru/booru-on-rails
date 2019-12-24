# frozen_string_literal: true

require 'retard_filter'

class PostsController < ApplicationController
  skip_authorization_check only: [:index]

  def index
    setup_pagination_and_tags

    @title = 'Searching Posts'
    @per_page = Post.posts_per_page
    @page_num = 1 if @page_num < 1
    @page_num = 10_000 if @page_num > 10_000

    set_content_hiding_filter Post, req_permission: :undelete

    @search = search_posts
    @posts = @search.records

    respond_to do |format|
      format.html { render }
      format.json { render json: @posts.map(&:as_json) }
    end
  end

  private

  def search_posts
    options = {
      per_page:          @per_page,
      page:              @page_num,
      include_deleted:   @include_deleted,
      access_options:    { is_mod: can?(:manage, Post) },
      include_destroyed: can?(:manage, Post)
    }

    Post.fancy_search(options) do |s|
      # Queries are used to enhance relevance sorting.

      if params[:author].present?
        if params[:author].include?('*')
          s.add_query(wildcard: { author: params[:author].downcase })
        else
          s.add_query(term: { author: params[:author].downcase })
        end

        s.add_filter(term: { anonymous: false }) if cannot?(:manage, Post)
      end

      s.add_query(match: { body: { query: params[:body], operator: 'and' } }) if params[:body].present?
      s.add_query(match: { subject: { query: params[:subject], operator: 'and' } }) if params[:subject].present?
      s.add_filter(term: { topic_position: 0 }) if params[:topics_only].present?

      # The below access_level filter prevents us from seeing things we shouldn't
      s.add_filter(term: { forum_id: params[:forum_id] }) if params[:forum_id].present?
      s.add_filter(terms: { access_level: Forum.access_level_for(current_user&.role) })

      # Mod+ stuff
      if can?(:manage, Post)
        s.add_filter(term: { fingerprint: params[:fingerprint] }) if params[:fingerprint].present?
        s.add_filter(term: { ip: params[:ip] }) if params[:ip].present? && (IPAddr.new(params[:ip]) rescue nil)
      end

      sort_fields = { relevance: :_score }
      sort_fields.default = :created_at

      sort_dirs = { asc: :asc }
      sort_dirs.default = :desc

      s.add_sort sort_fields[params[:sort_by]] => sort_dirs[params[:sort_dir]]
    end
  end
end
