# frozen_string_literal: true

class Filters::HidesController < ApplicationController
  before_action :check_auth
  before_action :require_tag

  def create
    @current_filter.hidden_tag_ids += [@tag.id]
    @current_filter.save
    @current_filter.update_index

    respond_to do |format|
      format.html { redirect_to tag_path(@tag), notice: 'Tag successfully hidden.' }
      format.json { head :ok }
    end
  end

  def destroy
    @current_filter.hidden_tag_ids -= [@tag.id]
    @current_filter.save
    @current_filter.update_index

    respond_to do |format|
      format.html { redirect_to tag_path(@tag), notice: 'Tag successfully unhidden.' }
      format.json { head :ok }
    end
  end

  private

  def require_tag
    @tag = Tag.find_by_slug_or_id(params[:tagname])
    raise ActiveRecord::RecordNotFound unless @tag
  end

  def check_auth
    authorize! :edit, @current_filter
  end
end
