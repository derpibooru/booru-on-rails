# frozen_string_literal: true

class Tags::AliasesController < ApplicationController
  skip_authorization_check

  def index
    @title = 'Tag Aliases'
    @aliased_tags = Tag.where.not(aliased_tag_id: nil).includes(:aliased_tag).order(name: :asc).page(params[:page]).per(50)
    respond_to do |format|
      format.html { render }
      format.json { render json: @aliased_tags }
    end
  end
end
