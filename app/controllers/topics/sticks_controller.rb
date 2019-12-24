# frozen_string_literal: true

class Topics::SticksController < ApplicationController
  before_action :load_topic
  before_action :check_auth

  # POST /forums/:forum_id/topics/:topic_id/stick
  def create
    if @topic.update(sticky: true)
      # Push sticky status to modfeed
      HidableLogger.log(@topic, 'Stickied', current_user.name)

      respond_to do |format|
        format.html { redirect_to forum_topic_path(@forum, @topic) }
        format.json { render head: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to(forum_topic_path(@forum, @topic), error: "Whoops, couldn't stick that topic for some reason") }
        format.json { render head: :error }
      end
    end
  end

  # DELETE /forums/:forum_id/topics/:topic_id/stick
  def destroy
    if @topic.update(sticky: false)
      # Push sticky status to modfeed
      HidableLogger.log(@topic, 'Unstickied', current_user.name)

      respond_to do |format|
        format.html { redirect_to forum_topic_path(@forum, @topic) }
        format.json { render head: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to(forum_topic_path(@forum, @topic), error: "Whoops, couldn't unstick that topic for some reason") }
        format.json { render head: :error }
      end
    end
  end

  private

  def load_topic
    @forum = Forum.find_by!(short_name: params[:forum_id])
    @topic = @forum.topics.find_by!(slug: params[:topic_id])
  end

  def check_auth
    authorize! :stick, @topic
  end
end
