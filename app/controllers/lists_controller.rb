# frozen_string_literal: true

class ListsController < ApplicationController
  include TimePeriod
  before_action :setup_pagination_and_tags
  before_action :set_image_filter
  before_action :get_time_period, except: [:my_comments, :recent_comments]
  skip_authorization_check

  def index
    @title = 'Rankings'
    @top_scoring_images, @all_time_top_scoring_images, @top_commented_images = Elasticsearch::Model.msearch!([
      get_top_scoring(3),
      get_top_scoring(3, all_time: true),
      get_top_commented(3)
    ]).map { |s| s.records(includes: :tags) }

    @interactions = ImageQuery.interactions((@top_commented_images.map(&:id) + @top_scoring_images.map(&:id) + @all_time_top_scoring_images.map(&:id)).compact.uniq, current_user.id) if current_user

    respond_to do |format|
      format.html
      format.json { render json: { top_scoring: @top_scoring_images, top_commented: @top_commented_images, all_time_top_scoring: @all_time_top_scoring_images, interactions: (@interactions || []) } }
    end
  end

  def recent_comments
    @title = 'Recent Comments - Lists'
    @hidden_tags = @current_filter.hidden_tag_ids
    @recent_comments = get_recent_comments(nil, nil, current_user).records(includes: { image: :tags })
    respond_to do |format|
      format.html
      format.json { render json: @recent_comments }
    end
  end

  def my_comments
    if !current_user && !params[:user_id]
      redirect_to '/', error: 'You must be logged in to view your comments'
      return
    end
    @user = nil
    @user = User.find_by_slug_or_id(params[:user_id]) rescue nil if params[:user_id]
    if params[:user_id] && !@user
      redirect_to '/', error: 'No such user exists'
      return
    end
    @title = "#{@user ? @user.name + "'s" : 'Your'} Comments - Lists"
    @hidden_tags = @current_filter.hidden_tag_ids
    @my_comments = get_recent_comments(nil, (params[:user_id] || current_user.id), current_user).records(includes: { image: :tags })
    respond_to do |format|
      format.html
      format.json { render json: @my_comments }
    end
  end

  private

  def get_top_commented(limit)
    options = default_image_filter_options
    options.delete :per_page
    Image.fancy_search(options.merge(size: limit, last_first_seen: @time_period)) do |s|
      s.add_sort comment_count: :desc
      s.add_sort id: :desc
    end
  end
end
