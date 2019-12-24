# frozen_string_literal: true

require 'booru'
require 'image_loader'
require 'fileutils'
require 'retard_filter'

class ImagesController < ApplicationController
  include RateLimitable
  include ImageUpload

  before_action -> { ratelimit 1, 10.seconds, t('booru.errors.upload_flooding', seconds: 10) }, only: [:create], unless: -> { current_user&.staff? }
  before_action :filter_banned_users, only: [:new, :create]
  before_action :setup_pagination_and_tags, :set_image_filter
  before_action :load_image_by_id, only: [:show]
  skip_authorization_check only: [:index, :scrape_url]

  def index
    if params[:format] == 'json' && params[:constraint]
      # Less intensive requirement.
      @include_deleted = params[:deleted]
      @images = index_constraints
      @image_ids = @images.map(&:id)
    else
      # Lag the index page by two minutes to allow people time to tag after uploading.
      @search = frontpage_images
      @images = @search.records(includes: [:tags, :user])
      @image_ids = @images.map(&:id)
      @interactions = ImageQuery.interactions(@image_ids, current_user.id) if current_user
    end

    @title = t('images.index.title')

    respond_to do |format|
      format.html
      format.json { render json: { images: @images.map(&:as_json), interactions: (@interactions || []) }.to_json }
    end
  end

  def show
    authorize! :read, Image
    Notification.mark_all_read(@image, current_user) if current_user

    @dupe_reports = DuplicateReport.includes(:image, :duplicate_of_image).where('image_id = ? OR duplicate_of_image_id = ?', @image.id, @image.id)

    if @image.hidden_from_users
      if @image.duplicate_id && !@image.can_see_when_hidden?(current_user)
        respond_to do |format|
          format.html { redirect_to short_image_path(@image.duplicate_id), notice: t('images.show.image_duplicate_redirect') }
          format.json { render json: @image.as_json }
        end
      else
        respond_to do |format|
          @title = t('images.errors.image_deleted')
          format.html do
            @comments = CommentQuery.paginate(image: @image, current_user: current_user, page: '0') if can? :manage, Image
            render action: 'deleted'
          end
          format.json do
            render json: @image.as_json
          end
        end
      end
      return
    end

    @search_query = params[:q]

    @interactions = ImageQuery.interactions(@image.id, current_user.id) if current_user

    @title = "##{@image.id} - #{@image.tag_list}"
    respond_to do |format|
      format.html do
        @comments = CommentQuery.paginate(image: @image, current_user: current_user, page: '0')
      end
      format.json do
        render json: @image.as_json.merge(interactions: (@interactions || []), spoilered: @current_filter&.image_spoilered_tag_ids(@image).present?)
      end
      format.any { head :bad_request }
    end
  end

  def new
    @title = t('images.new.title')
    authorize! :create, Image
    unless $flipper[:image_uploads].enabled?
      flash[:error] = t('images.errors.upload_disabled')
      redirect_back && return
    end
    @image = Image.new
    @image.anonymous = (current_user ? (current_user.anonymous_by_default? rescue false) : false)
  end

  def scrape_url
    if params[:url].present?
      scraped = Booru::Scraper.scrape(params[:url])
      render(json: scraped) && return if scraped.images.present? || scraped.errors.any?
    end
    render json: { errors: [t('images.errors.scraper_fetch_failed')] }, status: :unprocessable_entity
  end

  def create
    authorize! :create, Image
    unless $flipper[:image_uploads].enabled?
      flash[:error] = t('images.errors.upload_disabled')
      redirect_to(root_path) && return
    end

    @image = Image.new(image_params.merge(request_attributes))

    scraped_url = scraped_image_url do |metadata|
      if metadata.errors.any?
        @image.errors[:base].concat metadata.errors
      else
        # Keep manually input source over scraper source
        @image.source_url = metadata.source_url if @image.source_url.blank?
        if metadata.author_name.present?
          artist_tag = "artist:#{metadata.author_name.downcase}"
          @image.tag_input << ',' << artist_tag if @image.tag_input.downcase.exclude? artist_tag
        end
      end
    end

    @image.remote_image_url = scraped_url if scraped_url

    check_dnp

    immediate_deletion = RetardFilter.is_1cjb(@image.description)
    if immediate_deletion
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

    respond_to do |format|
      if @image.errors.blank? && @image.save
        if immediate_deletion
          redirect_to = short_image_path(@image)
          ImageHider.new(@image, user: current_user, reason: 'Rule #3: Gore').save

          format.html { redirect_to redirect_to, notice: t('images.create.image_insta_deleted') }
          format.json { render json: @image, location: @image }
        else
          SourceChange.add_to_img(@image, current_user, request, initial: true)
          Notification.watch(@image, current_user) if current_user && current_user.watch_on_upload
          NewImageLogger.log(@image)
          inc_user_stat :uploads

          format.html { redirect_to short_image_path(@image), notice: t('images.create.image_created') }
          format.json { render json: @image, status: :created, location: @image }
        end
      else
        format.html { render :new }
        format.json { render json: @image.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, Image
    @image = Image.find_by!(id: params[:id], hidden_from_users: true)

    # Update the image deleter.
    @image.deleted_by = current_user
    ImageDestroyer.new(@image).save
    respond_to do |format|
      format.html do
        redirect_to(images_path, notice: t('images.hard_destroy.success'))
      end
      format.json { head :ok }
    end
  end

  def navigate
    authorize! :read, Image
    if params[:do] == 'find'
      # do=find uses the current search scope; do=find_global defaults to the
      # index's lack of scope.
      # We're trying to find an image and direct the user to that page
      search = Image.fancy_search(default_image_filter_options) do |s|
        s.add_filter range: { id: { gt: params[:id].to_i } }
      end
      count_before = search.results.total_count
      page_num = if count_before != 0
        ((count_before + 1.0) / @per_page).ceil.to_i.to_s
      else
        1
      end

      redirect_to images_path(page: page_num)
    elsif %w[prev next].include?(params[:do])
      id = params[:id].to_i

      options = { query: params[:q], sorts: parse_sort }
      img = if params[:do] == 'prev'
        ImageLoader.new(default_image_filter_options.merge(options)).find_prev(id)
      else
        ImageLoader.new(default_image_filter_options.merge(options)).find_next(id)
      end

      respond_to do |format|
        format.html do
          if img
            redirect_to short_image_path(img.id, scope_key)
          else
            redirect_to short_image_path(params[:id], scope_key)
          end
        end
        format.json do
          if img
            render json: img.as_json
          else
            render json: {}
          end
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to '/' }
        format.json { render head: :ok }
      end
    end
  end

  private

  def index_constraints
    case params[:constraint]
    when 'id'
      constraint = :id
    when 'updated'
      constraint = :updated_at
    when 'created'
      constraint = :created_at
    when 'first_seen_at'
      constraint = :first_seen_at
    else
      return []
    end

    begin
      constraints = {}
      constraints[:hidden_from_users] = false unless @include_deleted

      search = Image.where(constraints)
      search = search.where("#{constraint} > ?", params[:gt]) if params[:gt]
      search = search.where("#{constraint} >= ?", params[:gte]) if params[:gte]
      search = search.where("#{constraint} < ?", params[:lt]) if params[:lt]
      search = search.where("#{constraint} <= ?", params[:lte]) if params[:lte]

      if params[:order].blank? || params[:order] == 'a'
        search = search.order(constraint => :asc)
      elsif params[:order] == 'd'
        search = search.order(constraint => :desc)
      else
        return []
      end
      return search.includes(:user, :tags).limit(@per_page).page(@page)
    rescue StandardError
      return []
    end
  end

  def load_image_by_id
    @image = Image.find(params[:id])
  end

  def load_non_destroyed_image
    @image = Image.find_by!(id: params[:id], destroyed_content: false)
  end

  def image_params
    params.require(:image).permit(:image, :image_cache, :source_url, :tag_input, :description, :anonymous)
          .merge(params.permit(:scraper_url, :scraper_cache))
  end

  def check_dnp
    tags = @image.tag_input.split(',').map { |t| t.strip.downcase }.uniq
    artist_tag_ids = Tag.where(namespace: 'artist').where(name: tags).pluck(:id)

    return if artist_tag_ids.empty?

    DnpEntry.where(aasm_state: 'listed').where(tag_id: artist_tag_ids).find_each do |dnp_entry|
      next if current_user && UserLink
              .where(tag_id: dnp_entry.tag_id)
              .where(aasm_state: 'verified')
              .where(user_id: current_user.id)
              .exists?

      artist_name = Tag.find(dnp_entry.tag_id).name_in_namespace

      if dnp_entry.dnp_type == 'Artist Upload Only'
        @image.errors[:base] << I18n.t('images.errors.tags_artist_dnp_html', dnp_type: dnp_entry.dnp_type, artist: artist_name, id: dnp_entry.id).html_safe
      elsif dnp_entry.dnp_type == 'No Edits' && tags.include?('edit')
        @image.errors[:base] << I18n.t('images.errors.tags_artist_dnp_html', dnp_type: dnp_entry.dnp_type, artist: artist_name, id: dnp_entry.id).html_safe
      end
    end
  end
end
