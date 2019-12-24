# frozen_string_literal: true

class Admin::BadgesController < ApplicationController
  before_action :check_auth, except: [:index]
  before_action :load_badge, only: [:edit, :update, :destroy]

  def index
    @title = 'Admin - Badges'
    authorize! :mod_read, Badge
    @badges = Badge.order(title: :asc).page(params[:page]).per(50)
    respond_to do |format|
      format.html
      format.json { render json: @badges }
    end
  end

  def new
    @title = 'New Badge'
    @badge = Badge.new
    respond_to do |format|
      format.html
      format.json { render json: @badge }
    end
  end

  def edit
    @title = "Editing Badge: #{@badge.title}"
  end

  def create
    @badge = Badge.new(badge_params)
    respond_to do |format|
      if @badge.save
        BadgeLogger.log(@badge.title, 'new', current_user)
        format.html { redirect_to admin_badges_path, notice: 'Badge was successfully created.' }
        format.json { render json: @badge, status: :created, location: admin_badges_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @badge.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @badge.update(badge_params)
        format.html { redirect_to admin_badges_path, notice: 'Badge was successfully updated.' }
        format.json { render json: @badge, status: :created, location: admin_badges_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @badge.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @badge.destroy
        BadgeLogger.log(@badge.title, 'destroyed', current_user)
        format.html { redirect_to admin_badges_url }
        format.json { head :ok }
      else
        format.html { render action: 'edit' }
        format.json { rendor json: @badge.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def check_auth
    authorize! :manage, Badge
  end

  def load_badge
    @badge = Badge.find_by(id: params[:id])
  end

  def badge_params
    params.require(:badge).permit(:title, :description, :uploaded_image, :disable_award, :priority)
  end
end
