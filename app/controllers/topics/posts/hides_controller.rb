# frozen_string_literal: true

class Topics::Posts::HidesController < ApplicationController
  before_action :load_post

  def create
    authorize! :hide, @post
    authorize! :hide, @topic if @post.first?

    PostHider.new(@post, user: current_user, reason: params[:deletion_reason]).save
    HidableLogger.log(@post, 'Deleted', current_user.name, params[:deletion_reason])

    flash[:notice] = 'Post deleted (hidden) from topic.'

    redirect_to short_topic_post_path(@forum, @topic, @post, anchor: "post_#{@post.id}")
  end

  def destroy
    authorize! :restore, @post
    PostUnhider.new(@post).save

    if @post.first?
      authorize! :restore, @topic
      TopicUnhider.new(@topic).save
    end

    HidableLogger.log(@post, 'Restored', current_user.name)
    redirect_to short_topic_post_path(@forum, @topic, @post, anchor: "post_#{@post.id}")
  end

  private

  def load_post
    @forum = Forum.find_by!(short_name: params[:forum_id])
    @topic = @forum.topics.find_by!(slug: params[:topic_id])
    @post  = @topic.posts.find_by!(destroyed_content: false, id: params[:post_id])
  end
end
