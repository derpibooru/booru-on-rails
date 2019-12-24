# frozen_string_literal: true

class UserLinksController < ApplicationController
  before_action :filter_banned_users, only: [:new, :create]
  before_action :require_user
  skip_authorization_check only: [:index]

  def index
    @links = current_user.links
    @title = 'Your Links'
    respond_to do |format|
      format.html
      format.json { render json: @links }
    end
  end

  def show
    @link = UserLink.find(params[:id])
    @title = 'Manage Link'
    authorize! :read, @link
  end

  def new
    @title = 'Create Link'
    authorize! :create, UserLink
    @link = UserLink.new

    respond_to do |format|
      format.html
      format.json { render json: @link }
    end
  end

  def create
    authorize! :create, UserLink
    @link = UserLink.new(link_params)
    @link.user = current_user
    respond_to do |format|
      if @link.save
        format.html { redirect_to user_link_path(@link), notice: "Link submitted! Please put '#{@link.verification_code}' on your linked webpage now." }
        format.json { render json: @link, status: :created, location: user_link_path(@link) }
      else
        format.html { render action: 'new' }
        format.json { render json: @link.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def link_params
    params.require(:user_link).permit(:uri, :public, :tag_name)
  end
end
