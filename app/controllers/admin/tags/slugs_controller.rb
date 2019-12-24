# frozen_string_literal: true

class Admin::Tags::SlugsController < ApplicationController
  before_action :check_auth
  before_action :load_tag

  def create
    @tag.set_slug
    @tag.save!
    @tag.update_index
    redirect_to edit_admin_tag_path(@tag), notice: 'Slug successfully rebuilt.'
  end

  private

  def check_auth
    authorize! :update, Tag
  end

  def load_tag
    @tag = Tag.find_by!(slug: params[:tag_id])
  end
end
