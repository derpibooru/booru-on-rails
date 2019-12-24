# frozen_string_literal: true

class Topics::MovesController < ApplicationController
  before_action :load_topic
  before_action :check_auth

  # POST /forums/:forum_id/topics/:topic_id/move
  def create
    if @topic.move_to_forum!(@target_forum)
      TopicMoveLogger.log(@topic, @forum.name, @target_forum.name, current_user.name)
      respond_to do |format|
        format.html { redirect_to forum_topic_path(@target_forum, @topic) }
        format.json { render head: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to(forum_topic_path(@forum, @topic), error: "Whoops, couldn't move that topic for some reason") }
        format.json { render head: :error }
      end
    end
  end

  private

  def load_topic
    @target_forum = Forum.find_by!(short_name: params[:target_forum_id])
    @forum = Forum.find_by!(short_name: params[:forum_id])
    @topic = @forum.topics.find_by!(slug: params[:topic_id])
  end

  def check_auth
    authorize! :move, @topic
  end
end
