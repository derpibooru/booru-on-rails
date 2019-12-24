# frozen_string_literal: true

class Topics::HidesController < ApplicationController
  before_action :load_topic
  before_action :check_auth

  # POST /forums/:forum_id/topics/:topic_id/hide
  def create
    TopicHider.new(@topic, user: current_user, reason: params[:deletion_reason]).save
    HidableLogger.log(@topic, 'Deleted', current_user.name, params[:deletion_reason])

    redirect_to forum_topic_path(@forum, @topic), notice: 'Topic hidden.'
  end

  # DELETE /forums/:forum_id/topics/:topic_id/hide
  def destroy
    TopicUnhider.new(@topic).save
    HidableLogger.log(@topic, 'Restored', current_user.name)

    redirect_to forum_topic_path(@forum, @topic)
  end

  private

  def load_topic
    @forum = Forum.find_by!(short_name: params[:forum_id])
    @topic = @forum.topics.find_by!(slug: params[:topic_id])
  end

  def check_auth
    authorize! :destroy, @topic
  end
end
