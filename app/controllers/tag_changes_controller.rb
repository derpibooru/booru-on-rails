# frozen_string_literal: true

class TagChangesController < ApplicationController
  def destroy
    authorize! :delete, TagChange
    @tag_change = TagChange.find(params[:id])
    @image = @tag_change.image
    @tag = @tag_change.tag
    TagChange.where(tag_name_cache: @tag_change.tag_name, image_id: @image.id).delete_all
    if @tag
      @image.remove_tags([@tag])
      @image.save
    end
    respond_to do |format|
      format.html { redirect_back notice: 'Removed tag change successfully.' }
      format.json { head :ok }
    end
  end

  def mass_revert
    authorize! :manage, TagChange
    TagChange.where(id: params[:ids]).find_each do |change|
      TagChange.create! request_attributes.merge(image: change.image, tag: change.tag, added: !change.added) if change.revert
    end

    redirect_back
  end
end
