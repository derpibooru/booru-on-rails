# frozen_string_literal: true

class Images::FeaturesController < ApplicationController
  before_action :load_image
  before_action :check_auth

  def create
    @image.features.create!(user: current_user)
    @image.update(tag_input: @image.tag_list + ', featured image')

    TagChange.create!(@image.tags_added.map { |tag| request_attributes.merge(added: true, image: @image, tag: tag) })
    TagChangeLogger.log(@image, current_user, @image.tags_added, @image.tags_removed)
    HidableLogger.log(@image, 'Featured', current_user.name)

    flash[:notice] = t('images.feature.success')

    redirect_to short_image_path(@image)
  end

  private

  def load_image
    @image = Image.find_by!(id: params[:image_id], hidden_from_users: false)
  end

  def check_auth
    authorize! :feature, @image
  end
end
