# frozen_string_literal: true

class Topics::Polls::VotersController < ApplicationController
  before_action :load_poll
  before_action :check_auth

  def index
    render partial: 'polls/poll_voters', locals: { poll: @poll }
  end

  private

  def load_poll
    @forum = Forum.find_by!(short_name: params[:forum_id])
    @topic = @forum.topics.find_by!(slug: params[:topic_id])
    @poll = Poll.find_by!(topic: @topic)
  end

  def check_auth
    authorize! :manage, @poll
  end
end
