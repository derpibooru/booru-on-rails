# frozen_string_literal: true

class Filters::CurrentsController < ApplicationController
  skip_authorization_check only: [:show]
  before_action :require_filter, only: [:update]

  def show
    respond_to do |format|
      format.html { redirect_to filter_path(@current_filter) }
      format.json { render json: @current_filter }
    end
  end

  def update
    authorize! :read, @filter

    if current_user
      current_user.set_filter!(@filter)
    else
      session[:filter_id] = @filter.id
    end

    respond_to do |format|
      format.html { redirect_back flash: { notice: "Switched to filter #{@filter.name}" } }
      format.json { head :ok }
    end
  end

  private

  def require_filter
    @filter = Filter.find(params[:id])
  end
end
