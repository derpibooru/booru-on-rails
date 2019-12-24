# frozen_string_literal: true

class ForumsController < ApplicationController
  skip_authorization_check only: [:index]
  before_action :load_forum, only: [:show]

  def index
    @forums = Forum.get_user_facing_list(current_user).includes(last_post: [:topic, :user])
    @title = 'Forums'
  end

  def show
    authorize! :read, @forum
    @topics =
      @forum
      .topics
      .where(hidden_from_users: false)
      .order('sticky DESC, last_replied_to_at DESC')
      .includes(:poll, :forum, :user, last_post: :user)
      .page(params[:page])
      .per(Topic.topics_per_page)
    @topic = Topic.new
    @topic.forum = @forum
    @title = "#{@forum.name} - Forums"
    Notification.mark_all_read(@forum, current_user) if current_user
    @topic.posts.build
    @topic.build_poll
    respond_to do |format|
      format.html
      format.json { render json: { topics: @topics } }
    end
  end

  private

  def load_forum
    @forum = Forum.find_by!(short_name: params[:id])
  end
end
