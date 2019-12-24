# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :load_forum, only: [:create, :new]
  before_action :load_forum_and_topic, except: [:create, :new]
  before_action :filter_banned_users, only: [:create]

  def show
    authorize! :read, @topic
    @title = "#{@topic.title} - #{@forum.name} - Forums"
    if params[:post_id]
      # Find which page this post is on, and set params[:page] appropriately
      post_to_find = Post.find_by(id: params[:post_id])
      params[:page] = @topic.page_for_post(post_to_find.id) rescue nil
      params[:post_id] = nil
    end
    @topic.increment!(:view_count)

    # Mark topic-related notifications as read, including notifications about
    # creation.
    if current_user
      Notification.mark_all_read(@topic, current_user)
      creation_notice = Notification.find_by(
        actor: @forum, actor_child: @topic
      )
      Notification.mark_read(creation_notice, current_user) if creation_notice
    end

    page = params[:page].to_i
    page = 1 if page < 1

    @posts =
      @topic
      .posts
      .where('topic_position >= ?', 25 * (page - 1))
      .where('topic_position < ?', 25 * page)
      .order(created_at: :asc, id: :asc)
      .includes(:user, topic: :forum)
      .limit(25)
      .to_a

    @posts = Kaminari.paginate_array(@posts, offset: 25 * (page - 1), limit: 25, total_count: @topic.post_count)

    @post = @topic.posts.build
    respond_to do |format|
      format.html
      format.json { render json: @posts }
    end
  end

  def new
    @topic = Topic.new
    @topic.forum = @forum
    @topic.posts.build
    @topic.build_poll
    @title = "New Topic in #{@forum.name}"
    authorize! :create, @topic
    redirect_back flash: { error: 'You need an account to create topics.' } if !current_user
  end

  def create
    @topic = Topic.new
    @topic.forum = @forum
    authorize! :create, @topic
    @topic.user = current_user
    if !current_user
      respond_to do |format|
        flash[:error] = 'Topic creation requires being logged in to an account.'
        format.html { redirect_to(forum_path(@forum)) }
        format.json { render head: :error }
      end
      return
    end
    if @topic.update(topic_params)
      # Create first post
      post = @topic.posts.order(created_at: :asc).first
      post.assign_attributes(request_attributes)
      post.anonymous = @topic.anonymous
      post.topic_position = 0
      if post.user
        inc_user_stat :forum_posts
        post.name_at_post_time = @topic.user.name
      end
      post.save!
      post.update_index(defer: false)
      Post.__elasticsearch__.refresh_index! # nasty hack

      Notification.watch(@topic, current_user) if current_user && current_user.watch_on_new_topic
      NewTopicLogger.log(@topic) if @forum.access_level == 'normal'
      respond_to do |format|
        format.html { redirect_to short_topic_path(@forum, @topic) }
        format.json { render head: :ok }
      end
    else
      respond_to do |format|
        format.html { render action: 'new', error: 'Whoops, something went wrong - look at the form below for more info' }
        format.json { render json: 'Error creating topic' }
      end
    end
  end

  def show_last_page
    authorize! :read, @topic
    page = @topic.page_for_post(@topic.last_post_id) rescue nil
    if page
      redirect_to url_for(controller: 'topics', action: 'show', forum_id: @forum[:short_name], id: @topic[:slug], page: page.to_s)
    else
      redirect_to short_topic_path(@topic)
    end
  end

  private

  def load_forum
    @forum = Forum.find_by!(short_name: params[:forum_id])
  end

  def load_forum_and_topic
    load_forum
    @topic = @forum.topics.find_by!(slug: params[:id])
  end

  def topic_params
    params.require(:topic).permit(
      :title,
      :anonymous,
      posts_attributes: [:body, :anonymous],
      poll_attributes:  Poll::POLL_ATTRIBUTES
    )
  end
end
