# frozen_string_literal: true

class Tags::WatchesController < ApplicationController
  before_action :require_user
  before_action :load_tag

  skip_authorization_check

  def create
    current_user.watched_tag_ids += [@tag.id]
    current_user.save
    respond_to do |format|
      format.html { redirect_to tag_path(@tag), notice: "You are now watching the tag '#{@tag.name}'" }
      format.js { head :ok }
    end
  end

  def destroy
    current_user.watched_tag_ids -= [@tag.id]
    current_user.save
    respond_to do |format|
      format.html { redirect_to tag_path(@tag), notice: "You are no longer watching the tag '#{@tag.name}'" }
      format.js { head :ok }
    end
  end

  private

  def load_tag
    @tag = Tag.find_by_slug_or_id(params[:tag_id])
    raise ActiveRecord::RecordNotFound unless @tag
  end
end
