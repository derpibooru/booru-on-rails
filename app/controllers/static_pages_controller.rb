# frozen_string_literal: true

class StaticPagesController < ApplicationController
  before_action :set_static_page, only: [:show, :edit, :update]
  before_action :check_auth, except: [:show]

  skip_authorization_check only: [:show]

  # GET /static_pages
  def index
    @title = 'Admin - Pages'
    @static_pages = StaticPage.all
  end

  # GET /static_pages/1
  def show
    @title = @static_page.title
  end

  # GET /static_pages/new
  def new
    @title = 'New Page'
    @static_page = StaticPage.new
  end

  # GET /static_pages/1/edit
  def edit
    @title = "Editing Page: #{@static_page.title}"
  end

  # POST /static_pages
  def create
    @static_page = StaticPage.new(static_page_params)

    if @static_page.save
      redirect_to @static_page, notice: 'Static page was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /static_pages/1
  def update
    if @static_page.update(static_page_params)
      redirect_to @static_page, notice: 'Static page was successfully updated.'
    else
      render :edit
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_static_page
    @static_page = StaticPage.find_by!(slug: params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def static_page_params
    params.require(:static_page).permit(:title, :slug, :body).merge(user: current_user)
  end

  def check_auth
    authorize! :manage, StaticPage
  end
end
