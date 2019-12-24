# frozen_string_literal: true

class FiltersController < ApplicationController
  before_action :require_filter, only: [:show, :edit, :update, :destroy]
  skip_authorization_check only: [:index]

  def index
    @title = 'Filters'
    @system_filters = Filter.where(system: true)
    @user_filters = current_user.filters if current_user

    if params[:fq] && params[:fq].present?
      @title = "Filters - Searching for #{params[:fq]}"
      setup_pagination_and_tags

      @search_filters = Filter.fancy_search(per_page: @per_page, page: @page_num) do |search|
        if params[:search_desc]
          search.add_query(bool: { should: [
            { match: { name: { query: params[:fq], operator: :and } } },
            { match: { description: { query: params[:fq], operator: :and } } }
          ] })
        else
          search.add_query(match: { name: { query: params[:fq], operator: :and } })
        end
        search.add_filter(term: { public: 'true' })
      end.records
    end

    respond_to do |format|
      format.html
      format.json { render json: { system_filters: @system_filters, user_filters: @user_filters, search_filters: (@search_filters || []) } }
    end
  end

  def new
    @title = 'New Filter'
    authorize! :create, Filter

    @filter = if params[:based_on_filter_id]
      Filter.find(params[:based_on_filter_id]).customizable_copy(current_user)
    else
      Filter.new
    end
  end

  def edit
    @title = "Editing Filter #{@filter.name}"
    redirect_to new_filter_path(based_on_filter_id: @filter.id) if cannot? :edit, @filter
  end

  def show
    @title = "#{@filter.name} - Filters"
    authorize! :read, @filter
    respond_to do |format|
      format.html
      format.json { render json: @filter }
    end
  end

  def create
    authorize! :create, Filter
    @filter = Filter.new(filter_params)
    @filter.user = current_user
    respond_to do |format|
      if @filter.save
        format.html { redirect_to @filter, notice: 'Filter was successfully created.' }
        format.json { render json: @filter, status: :created, location: filters_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @filter.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :edit, @filter
    params[:filter].delete(:public)
    respond_to do |format|
      if @filter.update(filter_params)
        @filter.update_index
        format.html { redirect_to @filter, notice: 'Filter was successfully updated.' }
        format.json { render json: @filter, status: :created, location: filters_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @filter.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :delete, @filter
    @filter.destroy
    respond_to do |format|
      format.html { redirect_to filters_url }
      format.json { head :ok }
    end
  end

  private

  def filter_params
    params.require(:filter).permit(:spoilered_tag_list, :hidden_tag_list, :description, :name, :public, :spoilered_complex_str, :hidden_complex_str)
  end

  def require_filter
    @filter = Filter.find_by(id: params[:id])
    authorize! :read, @filter
    redirect_back flash: { error: "Sorry, couldn't find that filter!" } if !@filter
  end
end
