# frozen_string_literal: true

class SourceChangesController < ApplicationController
  def destroy
    authorize! :delete, SourceChange
    @source_change = SourceChange.find(params[:id])
    @image = @source_change.image
    bad_val = @source_change.new_value
    SourceChange.where(new_value: bad_val, image_id: @image.id).delete_all
    if @image.source_url == bad_val
      latest_source = SourceChange.where(image_id: @image.id).order(created_at: :desc).first
      @image.source_url = if latest_source
        latest_source.new_value
      else
        ''
      end
      @image.save
    end

    respond_to do |format|
      format.html { redirect_back notice: 'Removed source change successfully.' }
      format.json { head :ok }
    end
  end
end
