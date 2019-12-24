# frozen_string_literal: true

class CommentsController < ApplicationController
  def index
    authorize! :manage, Comment
    @title = 'Comment Search'
    if params[:cq] && params[:cq].present?
      begin
        @search = Comment.fancy_search(
          per_page:        params[:per_page],
          page:            params[:page],
          include_deleted: true,
          access_options:  { is_mod: true },
          query:           params[:cq]
        )
        @comments = @search.records
      rescue SearchParsingError => ex
        flash[:error] = "Could not parse query: #{ex}"
      end
    end
  end
end
