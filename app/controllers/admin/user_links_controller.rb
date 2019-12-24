# frozen_string_literal: true

class Admin::UserLinksController < ApplicationController
  before_action :check_auth
  before_action :load_link, only: [:show, :edit, :update, :destroy]

  def index
    @title = 'Admin - User Links'
    authorize! :manage, UserLink
    @links = if params[:all] == 'true'
      UserLink
    elsif params[:q].present?
      UserLink.joins(:user).where('users.name ILIKE ? OR uri ILIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
    else
      UserLink.where(aasm_state: %w[unverified link_verified contacted])
    end.order(created_at: :desc).includes(:tag, user: :linked_tags).page(params[:page]).per(50)

    respond_to do |format|
      format.html
      format.json { render json: @links }
    end
  end

  def show
    @title = 'Admin - Manage User Link'
  end

  def new
    @title = 'New User Link'
    redirect_back error: "Can't create an arbitrary user link without an ID" if !params[:user_id]
    @link = UserLink.new
  end

  def create
    @link = UserLink.new(link_params)
    respond_to do |format|
      if @link.save
        format.html { redirect_to admin_user_link_path(@link), notice: 'Created link successfully!' }
        format.json { render json: @link, status: :created, location: admin_user_link_path(@link) }
      else
        format.html { render action: 'new' }
        format.json { render json: @link.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @title = "Editing User Link: #{@link.user.name}"
  end

  def update
    respond_to do |format|
      if @link.update(link_params)
        format.html { redirect_to admin_user_link_path(@link), notice: 'User Link successfully updated.' }
        format.json { render json: @link, status: :created, location: admin_user_link_path(@link) }
      else
        format.html { render action: 'new' }
        format.json { render json: @link.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @link.destroy
    respond_to do |format|
      format.html { redirect_to admin_user_links_path }
      format.json { head :ok }
    end
  end

  private

  def link_params
    params.require(:user_link).permit(:user_id, :uri, :public, :tag_name)
  end

  def check_auth
    authorize! :manage, UserLink
  end

  def load_link
    @link = UserLink.find_by(id: params[:id])
  end

  def modfeed_push(status)
    UserLinkLogger.log(status, @link.user, current_user)
  end
end
