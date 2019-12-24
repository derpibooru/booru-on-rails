# frozen_string_literal: true

require 'retard_filter'

class Topics::PostsController < ApplicationController
  include RateLimitable

  before_action :filter_banned_users, only: [:create, :edit, :update]
  before_action :load_topic
  before_action :load_post, only: [:edit, :update, :destroy]
  before_action -> { ratelimit 1, 30.seconds, t('booru.errors.post_flooding', seconds: 30) }, only: [:create], unless: :user_signed_in?

  skip_authorization_check only: [:index, :show]

  def index
    redirect_to short_topic_path(@forum, @topic)
  end

  def create
    @post = @topic.posts.new(post_params.merge(request_attributes))
    # To be populated after creation.
    @post.topic_position = nil
    @post.name_at_post_time = current_user.name if current_user
    if RetardFilter.is_1cjb(@post.body)
      PostHider.new(@post, user: current_user, reason: 'spam').save
      PostDestroyer.new(@post).save
      ip_ban = SubnetBan.new(
        reason:        'Persistent ban evasion - please contact a moderator to have your account whitelisted',
        note:          'This ban was created automatically by DJDavid98\'s 1CJBFilter™',
        specification: request.remote_ip,
        until:         'moon',
        enabled:       true
      )
      ip_ban.banning_user = current_user
      ip_ban.save

      render head: :ok
      return
    end
    authorize! :create, @post
    Notification.watch(@topic, current_user) if current_user && current_user.watch_on_reply
    if !current_user && (@post.body.include?('http://') || @post.body.include?('https://'))
      respond_to do |format|
        format.html { redirect_to(short_topic_path(@topic.forum, @topic, page: @topic.last_page), error: "Whoops, couldn't submit your post! You can't post links as an unregistered user.") }
        format.json { render head: :error }
      end
      return
    end
    if @post.save
      @post.update_index(defer: false)
      inc_user_stat :forum_posts
      Post.__elasticsearch__.refresh_index! # nasty hack
      respond_to do |format|
        format.html { redirect_to short_topic_post_path(@topic.forum, @topic, @post, anchor: "post_#{@post.id}"), notice: 'Your reply was posted' }
        format.json { render head: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to(short_topic_path(@topic.forum, @topic, page: @topic.last_page), error: "Whoops, couldn't submit your post! Make sure you've actually written something and the thread isn't locked/deleted.") }
        format.json { render head: :error }
      end
    end
  end

  def edit
    authorize! :edit, @post
    @title = "Editing post in #{@post.parent_title} - #{@post.topic.forum.name} - Forums"
  end

  def update
    authorize! :edit, @post
    @post.paper_trail.save_with_version if @post.versions.count < 1
    if @post.update(params.require(:post).permit(:body, :edit_reason).merge(edited_at: Time.zone.now))
      if RetardFilter.is_1cjb(params[:post][:body])
        PostHider.new(@post, user: current_user, reason: 'spam').save
        ip_ban = SubnetBan.new(
          reason:        'Persistent ban evasion - please contact a moderator to have your account whitelisted',
          note:          'This ban was created automatically by DJDavid98\'s 1CJBFilter™',
          specification: request.remote_ip,
          until:         'moon',
          enabled:       true
        )
        ip_ban.banning_user = current_user
        ip_ban.save
      end

      @post.update_index(defer: false)
      new_title = params[:post][:edit_title]
      if @post.first? && new_title
        topic = @post.topic
        topic.title = new_title
        if !topic.save
          respond_to do |format|
            format.html { redirect_to edit_forum_topic_post_path(topic.forum, topic, @post), notice: 'Your post could not be edited because the topic title is not between 4-96 characters.' }
            format.json { render head: :ok }
          end
          return
        end
      end
      respond_to do |format|
        format.html { redirect_to short_topic_post_path(@topic.forum, @topic, @post, anchor: "post_#{@post.id}"), notice: t('posts.update.success') }
        format.json { render head: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render head: :error }
      end
    end
  end

  def destroy
    authorize! :destroy, @post
    authorize! :hide, @topic if @post.first?

    PostHider.new(@post, user: current_user, reason: params[:deletion_reason]).save
    HidableLogger.log(@post, 'Deleted', current_user.name, params[:deletion_reason])
    PostDestroyer.new(@post).save

    flash[:notice] = 'Post hidden and contents destroyed.'

    redirect_to short_topic_post_path(@forum, @topic, @post, anchor: "post_#{@post.id}")
  end

  private

  def load_topic
    @forum = Forum.find_by!(short_name: params[:forum_id])
    @topic = @forum.topics.find_by!(slug: params[:topic_id])
  end

  def load_post
    @post = @topic.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:body, :anonymous)
  end
end
