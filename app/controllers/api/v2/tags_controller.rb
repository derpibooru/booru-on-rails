# frozen_string_literal: true

class Api::V2::TagsController < Api::V2::ApiController
  skip_authorization_check
  def show
    @tag = Tag.find_by(id: params[:id])
    respond_with @tag
  end

  def fetch_many
    @tags = if params[:name]
      Tag.where(name: params[:name])
    else
      Tag.where(id: params[:ids])
    end.includes(:aliased_tag, :implied_tags)
    respond_with(tags: @tags)
  end
end
