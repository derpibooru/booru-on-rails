# frozen_string_literal: true

class Admin::TagsController < ApplicationController
  before_action :load_tag, only: [:edit, :update, :destroy]

  def index
    @title = 'Admin - Tags'
    authorize! :mod_read, Tag
    @tags = if params[:q]
      @query = params[:q]
      Tag.order(created_at: :desc).where('name ILIKE ?', @query + '%')
    else
      Tag.order(created_at: :desc)
    end.page(params[:page]).per(50)

    respond_to do |format|
      format.html
      format.json { render json: @tags }
    end
  end

  def new
    @title = 'New Tag'
    authorize! :manage, Tag
    @tag = Tag.new
    respond_to do |format|
      format.html
      format.json { render json: @tag }
    end
  end

  def edit
    @title = "Editing Tag: #{@tag.name}"
    authorize! :update, Tag
  end

  def create
    authorize! :manage, Tag
    @tag = Tag.new(tag_params)
    respond_to do |format|
      if @tag.save
        @tag.update_index
        modfeed_push('created')
        format.html { redirect_to admin_tags_path, notice: 'Tag was successfully created.' }
        format.json { render json: @tag, status: :created, location: admin_tags_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :update, Tag
    if @tag.update(tag_params)
      modfeed_push('Short description edited', @tag.short_description) if @tag.previous_changes[:short_description]
      modfeed_push('Description edited', @tag.description) if @tag.previous_changes[:description]
      modfeed_push('Implications edited', @tag.implied_tag_list) if @tag.previous_changes[:implied_tags]

      if @tag.previous_changes[:aliased_tag_id]
        if @tag.aliased_tag
          create_alias = params[:merge_mode]&.to_sym != :hard_merge
          TagMergeJob.perform_later(@tag.id, @tag.aliased_tag_id, create_alias)
          modfeed_push((create_alias ? 'Aliased to' : 'Hard merged into'), @tag.aliased_tag.name.to_s)
        else
          removed_alias_target = @tag.previous_changes[:aliased_tag_id].first
          ReindexTagJob.perform_later(removed_alias_target)
          modfeed_push('Alias reset', '')
        end
      else
        @tag.update_index
      end

      respond_to do |format|
        format.html { redirect_to tag_path(@tag), notice: "Tag #{@tag.name} was successfully updated." }
        format.json { render json: @tag, status: :ok, location: admin_tags_path }
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :manage, Tag
    if @tag.destroy
      modfeed_push 'destroyed', "#{@tag.images_count} images"
      respond_to do |format|
        format.html { redirect_to admin_tags_path, notice: t('admin.tags.destroy.enqueued', tag: @tag.name) }
        format.json { render json: {}, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render action: :edit }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_tag
    @tag = Tag.find_by(slug: params[:id])
  end

  def modfeed_push(status, data = nil)
    TagLogger.log(@tag.name, status, data, current_user)
  end

  def tag_params
    params.require(:tag).permit(:name, :category, :remove_image, :uploaded_image, :short_description, :description, :mod_notes, :implied_tag_list, :merge_mode, :target_tag_name)
  end
end
