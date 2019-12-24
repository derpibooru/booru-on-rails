# frozen_string_literal: true

require 'image_loader'

class ActivitiesController < ApplicationController
  include TimePeriod

  skip_authorization_check

  def show
    @page_layout_class = 'layout--wide'

    if cacheable_request
      rendered_frontpage = $redis.get('rendered_frontpage')

      if rendered_frontpage
        render html: rendered_frontpage.html_safe, layout: true
        return
      end
    end

    @title = 'Homepage'
    setup_pagination_and_tags
    get_time_period
    set_image_filter
    watching_images = current_user && current_user.watching_images?
    @image_search, @top_scoring_images_search, @comments_search, @watched_images_search = Elasticsearch::Model.msearch! [
      frontpage_images,
      get_top_scoring(4, randomize: true),
      get_recent_comments(5),
      (ImageLoader.new(default_image_filter_options.merge(size: 15)).search('my:watched') if watching_images)
    ].compact
    @top_scoring_images = @top_scoring_images_search.records(includes: :tags)
    @watched_images = @watched_images_search.records(includes: :tags) if watching_images
    @images = @image_search.records(includes: :tags)
    @comments = @comments_search.records(includes: { image: :tags })

    @streams = ChannelQuery.live_and_static_sorted(false).limit(6)
    @topics = TopicQuery.recent(6)
    @featured_image = Image.joins(:features).order('image_features.created_at desc').first

    if current_user
      image_ids = (@images.map(&:id) + [@featured_image ? @featured_image.id : nil]) rescue []
      image_ids += @top_scoring_images.map(&:id) if @top_scoring_images
      image_ids += @watched_images.map(&:id) if @watched_images
      @interactions = ImageQuery.interactions(image_ids.compact.uniq, current_user.id)
    end

    if cacheable_request
      rendered_frontpage = render_to_string layout: false
      $redis.set('rendered_frontpage', rendered_frontpage)
      $redis.expire('rendered_frontpage', 60.seconds)
      render html: rendered_frontpage, layout: true
    else
      respond_to do |format|
        format.html { render }
      end
    end
  end

  private

  def cacheable_request
    @cacheable_request ||= (request.format.html? && session['warden.user.user.key'].nil? && session[:filter_id].nil?)
  end
end
