# frozen_string_literal: true

class CommissionsController < ApplicationController
  before_action :filter_banned_users, except: [:index, :show]
  before_action :load_commission, only: [:show, :edit, :update, :destroy]
  before_action :check_auth, only: [:edit, :update, :destroy]

  skip_authorization_check only: [:index, :show]

  def index
    @title = 'Commissions Directory'

    @search_item_type = params[:item_type].presence
    @search_categories = params[:category].presence
    @search_keywords = params[:keywords].presence
    @search_price_min = params[:price_min].present? ? params[:price_min].to_f : 0
    @search_price_max = params[:price_max].present? ? params[:price_max].to_f : 9999

    @random_seed = ('.' + Time.zone.now.strftime('%d%m%H')).to_f
    Commission.connection.execute "select setseed(#{@random_seed})"

    @query = Commission.where(open: true)
                       .where('commission_items_count > 0')
                       .preload(:user, commission_items: :example_image)

    @query = @query.where('categories @> ARRAY[?]::varchar[]', @search_categories) if @search_categories

    @query = @query.where('information ILIKE ? OR will_create ILIKE ?', "%#{like_sanitize(@search_keywords)}%", "%#{like_sanitize(@search_keywords)}%") if @search_keywords

    @query = @query.joins(:commission_items).where('commission_items.base_price BETWEEN ? AND ?', @search_price_min, @search_price_max)
    @query = @query.where('commission_items.item_type = ?', @search_item_type) if @search_item_type
    @query = @query.group(:id)

    @listable_commissions = @query.order(Arel.sql('random()')).page(params[:page]).per(Commission.listings_per_page)
  end

  def new
    @title = 'New Commission listing'
    authorize! :create, Commission
    @commission = current_user.build_commission
  end

  def create
    authorize! :create, Commission

    if current_user.linked_tags.blank?
      redirect_to user_links_path, error: t('commissions.error.link_missing')
      return
    end

    @commission = current_user.build_commission(commission_params)

    if @commission.save
      redirect_to commission_path(@commission), notice: 'Commission information created.'
    else
      render :new
    end
  end

  def show
    @listing_name = @user == current_user ? 'My Commissions' : "#{@user.name}'s Commissions"
    @title = @listing_name
    @links = @user.links.verified.where(public: true)
    @links = @user.links.verified if can?(:manage, UserLink)
  end

  def edit
    @title = 'Edit Commission Listing'
    @linkable_tags = @user.linked_tags
  end

  def update
    if @commission.user.linked_tags.blank?
      redirect_to user_links_path, error: t('commissions.error.link_missing')
      return
    end

    if @commission.update(commission_params)
      redirect_to commission_path(@commission), notice: t('commissions.listing_saved')
    else
      render :edit
    end
  end

  def destroy
    @commission.destroy
    redirect_to commissions_path, notice: t('commissions.listing_deleted')
  end

  private

  def load_commission
    @user = User.find_by!(slug: params[:id])
    @commission = Commission.find_by!(user: @user)
  end

  def commission_params
    params.require(:commission).permit(:open, :information, :contact, :will_create, :will_not_create, :sheet_image_id, categories: [])
  end

  def check_auth
    authorize! :edit, @commission
  end

  def like_sanitize(value)
    @like_regex = /([\\%_])/
    @like_escape = '\\\\\1'
    value.gsub(@like_regex, @like_escape)
  end
end
