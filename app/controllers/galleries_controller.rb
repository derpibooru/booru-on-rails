# frozen_string_literal: true

class GalleriesController < ApplicationController
  before_action :load_gallery, only: [:show, :edit, :update, :destroy]
  before_action :load_user, only: [:index]
  before_action :setup_pagination_and_tags, only: [:index, :show]
  before_action :set_image_filter, only: [:show]

  skip_authorization_check only: [:index]

  def index
    if @user
      @title = @user == current_user ? 'My Galleries' : "#{@user.name}'s Galleries"
      @galleries = @user.galleries.includes(:creator, :thumbnail).page(@page_num).per(@per_page)
    else
      @show_search = true
      @title = 'Public Galleries'
      @galleries = search_galleries
    end

    respond_to do |format|
      format.html
      format.json { render json: @galleries.map { |g| g.as_json(include_images: params[:include_images].present?) } }
    end
  end

  def show
    authorize! :read, @gallery

    @title = @gallery.title
    @search = load_gallery_images

    # Get gallery_id to show up in search bar
    params.merge!(q: "gallery_id:#{@gallery.id}", sf: "gallery_id:#{@gallery.id}", sd: @gallery.position_order)

    @images = @search.records

    # Extra hacks to get previous and next page editing to work
    @gallery_prev, @gallery_next = prev_next_page_images
    image_ids = [*@gallery_prev, *@images, *@gallery_next].map(&:id).compact
    @interactions = ImageQuery.interactions(image_ids, current_user.id) if current_user
    js_datastore['gallery-images'] = image_ids

    Notification.mark_all_read(@gallery, current_user) if current_user

    respond_to do |format|
      format.html { render locals: { random_image_href: gallery_random_path(@gallery) } }
      format.json { render json: { gallery: @gallery.as_json, images: @images, interactions: (@interactions || []) } }
    end
  end

  def new
    authorize! :create, Gallery
    @gallery = Gallery.new
  end

  def create
    authorize! :create, Gallery
    @gallery = current_user.galleries.build(gallery_params)

    if @gallery.save
      if params[:gallery][:with_image].present?
        image = Image.find_by(id: params[:gallery][:with_image])
        @gallery.add(image) if image
      end

      redirect_to gallery_path(@gallery), notice: 'Gallery was successfully created.'
    else
      render :new
    end
  end

  def edit
    authorize! :edit, @gallery
  end

  def update
    authorize! :edit, @gallery

    if @gallery.update(gallery_params)
      redirect_to gallery_path(@gallery), notice: 'Gallery was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize! :edit, @gallery

    @gallery.destroy

    redirect_to galleries_path, notice: 'Gallery was successfully destroyed.'
  end

  private

  def search_galleries
    Gallery.fancy_search(per_page: @per_page, page: @page_num) do |s|
      s.add_query wildcard: { title: "*#{params[:title].downcase}*" } if params[:title].present?
      s.add_query match: { description: { query: params[:description], operator: :and } } if params[:description].present?
      s.add_filter term: { creator: params[:creator].downcase } if params[:creator].present?
      s.add_filter term: { watcher_ids: current_user.id } if params[:my_subs].present? && current_user
      s.add_filter term: { image_ids: params[:include_image].to_i } if params[:include_image].present?
      s.add_filter range: { image_count: { gt: 0 } } if params[:show_empty].blank?
      sf = Gallery.allowed_sort_fields.detect { |f| params[:sf]&.to_sym == f } || :created_at
      sd = params[:sd] == 'asc' ? :asc : :desc
      s.add_sort sf => sd
    end.records
  end

  def prev_next_page_images
    return if cannot?(:edit, @gallery)

    @page_num = 1 if @page_num < 1
    prev_page_end = (@page_num - 1) * @per_page - 1
    next_page_start = @page_num * @per_page
    [gallery_image(prev_page_end), gallery_image(next_page_start)]
  end

  def gallery_image(offset)
    if offset.between? 1, @gallery.image_count
      options = default_image_filter_options.except(:page, :per_page)
      options[:size] = 1
      options[:from] = offset
      load_gallery_images(options).records.first
    end
  end

  def load_gallery_images(options = default_image_filter_options)
    ImageLoader.new(options).gallery(@gallery.id, @gallery.position_order)
  end

  def load_gallery
    @gallery = Gallery.find(params[:id])
  end

  def load_user
    @user = User.find_by(name: params[:user])
  end

  def gallery_params
    params.require(:gallery).permit(:title, :spoiler_warning, :description, :thumbnail_id, :order_position_asc)
  end
end
