# frozen_string_literal: true

class Tags::UsagesController < ApplicationController
  before_action :load_tag
  before_action :check_auth

  def show
    @title = "Tag Usage: #{@tag.name}"
    if @tag.aliased_tag
      redirect_to @tag.aliased_tag, notice: "This tag ('#{@tag.name}') has been aliased to the tag '#{@tag.aliased_tag.name}'"
      return
    end

    @filters_spoilering = Filter.where('spoilered_tag_ids @> ARRAY[?]', @tag.id).order(user_count: :desc)
    @filters_hiding = Filter.where('hidden_tag_ids @> ARRAY[?]', @tag.id).order(user_count: :desc)
    @users_watching = User.where('watched_tag_ids @> ARRAY[?]', @tag.id).order(name: :asc)
  end

  private

  def load_tag
    @tag = Tag.find_by_slug_or_id(params[:tag_id])
    raise ActiveRecord::RecordNotFound unless @tag
  end

  def check_auth
    authorize! :mod_read, Tag
  end
end
