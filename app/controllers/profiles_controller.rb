# frozen_string_literal: true

class ProfilesController < ApplicationController
  include UserQuery

  skip_authorization_check
  before_action :filter_banned_users, only: [:edit, :update]
  before_action :load_user, except: [:index]

  def index
  end

  def show
    setup_pagination_and_tags
    set_image_filter

    @links = @user.links.verified.where(public: true)
    @links = @user.links.verified if can?(:manage, UserLink)
    @last_activity = UserIp.where(user_id: @user.id).order(updated_at: :desc).first&.updated_at if can? :mod_read, User

    @tags = Tag.where(id: @links.select(:tag_id)).sort_by(&:name).uniq

    @image_search = ImageLoader.new(default_image_filter_options.merge(per_page: 5))
    @posts_search = Post.fancy_search(size: 6) do |search|
      search.add_filter term: { user_id: @user.id }
      search.add_filter term: { anonymous: false }
      search.add_filter term: { access_level: 'normal' }
    end
    @tags_search = Image.fancy_search(default_image_filter_options.merge(per_page: 5)) do |search|
      search.add_filter terms: { tag_ids: @tags.map(&:id) }
    end
    @comments_search = get_recent_comments(3, @user.id, nil).records
    @recent_uploads, @recent_favs, @recent_comments, @recent_posts, @recent_artwork = Elasticsearch::Model.msearch!([
      @image_search.search("uploader_id:#{@user.id}"),
      @image_search.search("faved_by_id:#{@user.id}"),
      @comments_search.response,
      @posts_search,
      @tags_search
    ]).map(&:records)
    @recent_comments = @recent_comments.select { |c| c.image && !c.image.hidden_from_users }
    @recent_galleries = @user.galleries.limit(5).includes(:creator, :thumbnail)

    @interactions = ImageQuery.interactions((@recent_uploads + @recent_favs + @recent_artwork).map(&:id).compact.uniq, current_user.id) if current_user

    @bans = @user.bans.order(created_at: :desc)
    @title = "#{@user.name}'s profile"
    respond_to do |format|
      format.html { render }
      format.json { render json: @user.as_json }
    end
  end

  def edit
    @title = 'Updating Profile Description'
    authorize! :manage, User if !current_user || current_user.id != @user.id
    render 'profiles/edit'
  end

  def update
    authorize! :manage, User if !current_user || current_user.id != @user.id
    description = params[:body]
    title = params[:title]

    # Remove all the unicode spaces from the title.
    title.gsub! /[\t\u{feff}\u{180e}\u{3000}\u{202f}\u{2000}-\u{200b}]/, ''
    title.strip!

    # Hide title and description if they are empty.
    @user.personal_title = title.presence
    @user.description = description.presence

    if @user.save
      respond_to do |format|
        format.html { redirect_to profile_path(@user.slug), notice: 'Description successfully updated.' }
        format.json { render json: :ok }
      end
    else
      respond_to do |format|
        format.html { render 'profiles/edit' }
        format.html { render json: :error }
      end
    end
  end
end
