# frozen_string_literal: true

class Admin::Tags::ReindicesController < ApplicationController
  before_action :check_auth
  before_action :load_tag

  def create
    if @tag.aliased_tag_id
      ReindexTagJob.perform_later(@tag.aliased_tag_id)
      modfeed_push('reindexed alias', @tag.aliased_tag.name)
    else
      ReindexTagJob.perform_later(@tag.id)
      modfeed_push('reindexed', '')
    end

    respond_to do |format|
      format.html { redirect_to admin_tags_path, notice: "Tag #{@tag.name} is now being reindexed." }
      format.json { render json: @tag, status: :ok }
    end
  end

  private

  def check_auth
    authorize! :manage, Tag
  end

  def load_tag
    @tag = Tag.find_by!(slug: params[:tag_id])
  end

  def modfeed_push(status, data = nil)
    TagLogger.log(@tag.name, status, data, current_user)
  end
end
