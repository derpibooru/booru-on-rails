# frozen_string_literal: true

class Images::CommentsController < ApplicationController
  include RateLimitable

  before_action :load_image
  before_action :check_auth
  before_action :load_comment, only: [:show, :edit, :update, :destroy]
  before_action :filter_banned_users, only: [:create, :edit, :update]

  before_action -> { ratelimit 1, 30.seconds, t('booru.errors.comment_flooding', seconds: 30) }, only: [:create], unless: :user_signed_in?

  skip_authorization_check only: [:show]

  def index
    respond_to do |format|
      @comments = CommentQuery.paginate(image: @image, current_user: current_user, page: params[:page], comment_id: params[:comment_id])
      params[:comment_id] = nil
      format.html { render partial: 'images/image_comments', layout: false, locals: { comments: @comments, image: @image } }
      format.json { render json: { comments: @comments, total: @image.comments_count } }
    end
  end

  def create
    @comment = @image.comments.new(comment_params.merge(request_attributes))
    @comment.name_at_post_time = current_user.name if current_user

    authorize! :create, @comment

    Notification.watch(@image, current_user) if current_user && current_user.watch_on_reply

    @image.update_index

    if @comment.save
      inc_user_stat :comments_posted
      NewCommentLogger.log(@comment)
      respond_to do |format|
        format.html do
          flash[:notice] = t('comments.create.success')
          redirect_to image_path(@image, anchor: "comment_#{@comment.id}")
        end
        format.js do
          params[:comment]    = nil
          params[:comment_id] = @comment.id
          @comments = CommentQuery.paginate(image: @image, current_user: current_user, page: nil, comment_id: params[:comment_id])
          render partial: 'images/image_comments', locals: { image: @image, comments: @comments, comment: @comment }, layout: false
        end
      end
      return
    else
      flash[:error] = t('comments.create.error')
    end

    respond_to do |format|
      format.html { redirect_to image_path(@image) }
      format.js   { head 400 }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @comment }
      format.all  { render layout: false }
    end
  end

  def edit
    authorize! :edit, @comment
    @title = t('comments.edit.title', target: @comment.parent_title)
  end

  def update
    authorize! :edit, @comment
    @comment.paper_trail.save_with_version if @comment.versions.count < 1
    if @comment.update(params.require(:comment).permit(:body, :edit_reason).merge(edited_at: Time.zone.now))
      @comment.update_index
      CommentEditLogger.log(@comment, current_user)
      respond_to do |format|
        format.html { redirect_to image_path(@image, anchor: "comment_#{@comment.id}"), flash: { notice: t('comments.update.success') } }
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
    authorize! :destroy, @comment

    CommentDestroyer.new(@comment).save
    flash[:notice] = t('comments.destroy.content_destroyed')

    redirect_to image_path(@image, anchor: "comment_#{@comment.id}")
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def load_comment
    @comment = Comment.find(params[:id])
  end

  def check_auth
    authorize! :read, @image
  end

  def comment_params
    params.require(:comment).permit(:body, :anonymous)
  end
end
