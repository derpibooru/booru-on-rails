# frozen_string_literal: true

class Posts::PostedsController < ApplicationController
  skip_authorization_check only: [:show]

  def show
    @include_deleted = can?(:undelete, Post)
    if params[:user_id] && !(current_user && params[:user_id] == current_user.id.to_s)
      user = User.find(params[:user_id])
      @title = "#{user.name}'s Forum Posts"
    else
      if !current_user
        redirect_back error: 'You must be logged in to view your posts.'
        return
      end

      @title = 'My Forum Posts'
      user = current_user
    end

    @username = user.name
    @per_page = Post.posts_per_page
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @search = Post.fancy_search(
      include_deleted: @include_deleted,
      per_page:        @per_page,
      page:            @page,
      access_options:  { is_mod: can?(:manage, Post) }
    ) do |search|
      search.add_filter terms: { access_level: Forum.access_level_for(current_user&.role) }
      search.add_filter term: { user_id: user.id }
      search.add_filter term: { anonymous: false } unless can? :manage, Post
      search.add_sort updated_at: :desc
    end

    @posts = @search.records
    respond_to do |format|
      format.html { render }
      format.json { render json: @posts.map(&:as_json) }
    end
  end
end
