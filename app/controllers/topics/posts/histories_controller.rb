# frozen_string_literal: true

class Topics::Posts::HistoriesController < ApplicationController
  before_action :load_post

  def show
    @title = "Post History for #{@post.user.name} on #{@topic.title} - Forums"
    authorize! :read, @post
  end

  private

  def load_post
    @forum = Forum.find_by!(short_name: params[:forum_id])
    @topic = @forum.topics.find_by!(slug: params[:topic_id])
    @post  = @topic.posts.find(params[:post_id])
  end
end
