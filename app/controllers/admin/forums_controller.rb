# frozen_string_literal: true

class Admin::ForumsController < ApplicationController
  before_action :check_auth
  before_action :set_forum, only: [:show, :edit, :update, :destroy]

  def index
    @title = 'Admin - Forums'
    @forums = Forum.order(name: :asc)
    respond_to do |format|
      format.html
      format.json { render json: @forums }
    end
  end

  def new
    @title = 'New Forum'
    @forum = Forum.new
    respond_to do |format|
      format.html
      format.json { render json: @forum }
    end
  end

  def edit
    @title = "Editing Forum: #{@forum.name}"
  end

  def show
    @title = "Details for Forum: #{@forum.name}"
  end

  def create
    @forum = Forum.new(forum_params)
    respond_to do |format|
      if @forum.save
        format.html { redirect_to admin_forums_path, notice: 'Forum was successfully created.' }
        format.json { render json: @forum, status: :created, location: admin_forums_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @forum.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @forum.update(forum_params)
        format.html { redirect_to admin_forums_path, notice: 'Forum was successfully updated.' }
        format.json { render json: @forum, status: :created, location: admin_forums_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @forum.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @forum.destroy
    respond_to do |format|
      format.html { redirect_to admin_forums_url }
      format.json { head :ok }
    end
  end

  private

  def set_forum
    @forum = Forum.find_by(short_name: params[:id])
  end

  def check_auth
    authorize! :manage, Forum
  end

  def forum_params
    params.require(:forum).permit(:name, :short_name, :description, :access_level)
  end
end
