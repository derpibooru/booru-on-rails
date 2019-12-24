# frozen_string_literal: true

class Topics::LocksController < ApplicationController
  before_action :load_topic
  before_action :check_auth

  # POST /forums/:forum_id/topics/:topic_id/lock
  def create
    if @topic.update(lock_params)
      # Push lock status to modfeed
      HidableLogger.log(@topic, 'Locked', current_user.name, params[:lock_reason])

      respond_to do |format|
        format.html { redirect_to forum_topic_path(@forum, @topic) }
        format.json { render head: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to(forum_topic_path(@forum, @topic), error: "Whoops, couldn't lock that topic for some reason") }
        format.json { render head: :error }
      end
    end
  end

  # DELETE /forums/:forum_id/topics/:topic_id/lock
  def destroy
    if @topic.update(unlock_params)
      # Push lock status to modfeed
      HidableLogger.log(@topic, 'Unlocked', current_user.name)

      respond_to do |format|
        format.html { redirect_to forum_topic_path(@forum, @topic) }
        format.json { render head: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to(forum_topic_path(@forum, @topic), error: "Whoops, couldn't unlock that topic for some reason") }
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
    authorize! :lock, @topic
  end

  def lock_params
    {
      locked_at:   Time.zone.now,
      locked_by:   current_user,
      lock_reason: params[:lock_reason]
    }
  end

  def unlock_params
    {
      locked_at:   nil,
      locked_by:   nil,
      lock_reason: nil
    }
  end
end
