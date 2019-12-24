# frozen_string_literal: true

require 'image_loader'
require 'captcha'

class ApplicationController < ActionController::Base
  include UserFilter
  include UserAttribution
  include JsDatastore
  include CaptchaVerifier

  before_action :kill_non_api_request
  before_action :start_timer
  before_action :set_paper_trail_whodunnit
  protect_from_forgery with: :exception, prepend: true

  rescue_from Can4::AccessDenied do |_exception|
    user = current_user ? current_user.name : 'Dave'
    redirect_to root_url, flash: { error: t('booru.errors.access_denied', user: user) }
  end
  rescue_from ActiveRecord::RecordNotFound do |_exception|
    redirect_to root_url, flash: { error: t('booru.errors.record_not_found') }
  end
  rescue_from ActionController::UnknownFormat do |_exception|
    redirect_to errors_not_found_path
  end
  rescue_from ActionController::InvalidAuthenticityToken do |_exception|
    respond_to do |format|
      format.json { render json: { error: 'Invalid CSRF token' }, status: :forbidden }
      format.any  { redirect_back flash: { error: 'Invalid CSRF token.' } }
    end
  end

  check_authorization unless: :devise_controller?
  before_action :configure_permitted_parameters_for_devise, if: :devise_controller?
  before_action :login_with_token_if_provided
  before_action :current_ban
  before_action :load_filter
  before_action :load_unread_pms
  skip_before_action :verify_authenticity_token, if: proc { |c| c.login_with_token_if_provided; c.using_apikey? }

  def kill_non_api_request
    return if request.format.json? && request.get?

    render html: "Non-API request killed"
  end

  def login_with_token_if_provided
    return if @using_apikey

    params[:auth_token] = nil
    if params[:key].present? && using_api?
      user = params[:key] && User.find_by(authentication_token: params[:key])
      if user
        @using_apikey = true
        sign_in user, store: false
      else
        render json: { error: 'Invalid API key.' }, status: :forbidden
      end
    end
  end

  def using_apikey?
    @using_apikey || false
  end

  def using_api?
    request.format.json? || request.format.rss?
  end

  def start_timer
    @start_time = Time.zone.now
  end

  private

  def inc_user_stat(stat_name)
    current_user.inc_stat(stat_name) if current_user
  end

  def load_unread_pms
    @unread = Conversation.where("((to_id = ? AND to_read = 'f') OR (from_id = ? AND from_read = 'f')) AND (NOT ((to_id = ? AND to_hidden = 't') OR (from_id = ? AND from_hidden = 't')))", current_user.id, current_user.id, current_user.id, current_user.id) if current_user

    true
  end

  def load_filter
    @current_filter ||= Filter.for(current_user, session[:filter_id] || params[:filter_id])
    @show_hidden = params[:hidden] == '1'
  end

  def setup_pagination_and_tags
    @per_page = (current_user ? current_user.images_per_page : 15)
    if params[:perpage]
      per_page = params[:perpage].to_i
      @per_page = per_page if per_page.between? 1, Booru::CONFIG.settings[:max_images_per_page]
    end
    @page_num = params[:page].to_i
    @hidden_tags = @current_filter.hidden_tag_ids
    @hidden_filter = @current_filter.hidden_complex(is_mod: can?(:manage, Image), user: current_user)
    @spoilered_tags = @current_filter.spoilered_tag_ids

    if current_user && !@show_hidden
      if @current_filter.hidden_complex_str.present?
        query_str = Filter.normalize_user_query_program(@current_filter.hidden_complex_str)
        @hidden_filter = Filter.parse_user_query_program("(#{query_str}) || my:hidden", Image, is_mod: can?(:manage, Image), user: current_user)
      else
        @hidden_filter = Filter.parse_user_query_program('my:hidden', Image, is_mod: can?(:manage, Image), user: current_user)
      end
    end
  end

  def current_ability
    @current_ability ||= ::Ability.new(current_user, request.remote_ip)
  end

  def es_wildcard_escape(str)
    str.gsub('*', '\*').gsub('?', '\?')
  end

  def set_image_filter
    set_content_hiding_filter Image, req_permission: :undelete
  end

  def set_content_hiding_filter(model, req_permission: :manage)
    # Sets @include_deleted instance variable indicating included deleted
    # content (true), omitted deleted content (false), or only deleted
    # content (:only). Note it is left nil if the user lacks the specified
    # permission. This is predominantly used to interface with FancySearchable.
    if can? req_permission, model
      @include_deleted = if params[:del] == 'only'
        :only
      else
        params[:del].present?
      end
    end
  end

  # Default options Hash for image searching.
  def default_image_filter_options
    {
      hidden:          @hidden_filter,
      include_deleted: @include_deleted,
      hidden_tags:     @hidden_tags,
      per_page:        @per_page,
      page:            @page_num,
      title:           @title,
      access_options:  { is_mod: can?(:manage, Image), user: current_user }
    }
  end

  def frontpage_images
    ImageLoader.new(default_image_filter_options).search('created_at.lte: 3 minutes ago')
  end

  def scope_key
    @scope_key ||= params.permit(:q, :sf, :sd).to_h
  end

  helper_method :scope_key

  def parse_sort
    sd = [:asc, :desc].detect { |d| (params[:sd].to_sym rescue nil) == d }
    sd ||= :desc

    sf = [:created_at, :updated_at, :first_seen_at, :width, :height, :score, :relevance, :comments, :tag_count, :random, :wilson].detect { |f| (params[:sf].to_sym rescue nil) == f }

    return [{ 'galleries.position' => { 'order' => sd, 'nested_path' => 'galleries', 'nested_filter' => { 'term' => { 'galleries.id' => Regexp.last_match(1).to_i } } } }] if params[:sf] =~ /\Agallery_id:(\d+)\z/

    return [_random: sd, random_seed: Regexp.last_match(1).to_i] if params[:sf] =~ /\Arandom:(\d+)\z/

    sf ||= :created_at
    if sf == :relevance
      sf = :_score
    elsif sf == :comments
      sf = :comment_count
    elsif sf == :random
      sf = :_random
    elsif sf == :wilson
      sf = :wilson_score
    end

    if [:created_at, :updated_at, :_random].include?(sf)
      [sf => sd]
    else
      [{ sf => sd }, { id: :desc }]
    end
  end

  def captcha_verified?(check_account = true)
    (check_account && current_user) || verify_captcha
  end

  protected

  def configure_permitted_parameters_for_devise
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
    if current_ban.blank?
      devise_parameter_sanitizer.permit(:account_update, keys: User::ALLOWED_PARAMETERS)
    else
      devise_parameter_sanitizer.permit(:account_update, keys: User::ALLOWED_PARAMETERS_BANNED)
    end
  end

  def get_recent_comments(limit = nil, user_id = nil, viewing_user = nil)
    Comment.fancy_search(
      per_page:        (limit || @per_page),
      page:            @page_num,
      include_deleted: can?(:manage, Comment)
    ) do |s|
      s.add_filter(term: { user_id: user_id.to_s }) if user_id
      s.add_filter(bool: { must_not: { terms: { image_tag_ids: @hidden_tags } } })
      s.add_filter(term: { anonymous: false }) unless !user_id || (viewing_user && viewing_user.id == user_id) || can?(:manage, Comment)
      s.add_filter(range: { posted_at: { gt: 'now-1w' } }) if !user_id
    end
  end

  def get_top_scoring(limit, all_time: false, randomize: false)
    options = default_image_filter_options

    options.delete(:per_page)
    options[:last_first_seen] = (@time_period unless all_time)
    options[:size] = limit
    options[:from] = rand(26) if randomize

    Image.fancy_search(options) do |search|
      search.add_sort score: :desc
      search.add_sort first_seen_at: :desc
    end
  end

  def redirect_back(**options)
    super(fallback_location: root_path, **options)
  end

  private

  def after_sign_in_path_for(_resource)
    root_path
  end

  def after_sign_out_path_for(_resource)
    root_path
  end
end
