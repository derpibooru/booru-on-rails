# frozen_string_literal: true

class Images::TagsController < ApplicationController
  include RateLimitable

  before_action :filter_banned_users
  before_action :load_image
  before_action :check_auth

  before_action -> { ratelimit 1, 5.seconds, t('booru.errors.metadata_flooding', seconds: 5) }, unless: -> { current_user&.staff? }

  def update
    if !captcha_verified?
      @image.errors[:base] << t('images.update_metadata.errors.captcha_unverified')
      render partial: 'images/image_tags', layout: false, locals: { image: @image }
      return
    end

    @image.with_lock do
      @image.tag_input = params[:image][:tag_input]
      @image.tags_compare_against = params[:image][:old_tag_list]
      if @image.save
        change_attrs = request_attributes.merge(image: @image)

        if @image.tags_added.any? || @image.tags_removed.any?
          tag_changes = @image.tags_added.map   { |tag| change_attrs.merge(tag: tag, added: true) } +
                        @image.tags_removed.map { |tag| change_attrs.merge(tag: tag, added: false) }
          TagChange.create! tag_changes
          TagChangeLogger.log(@image, current_user, @image.tags_added, @image.tags_removed)
          inc_user_stat :metadata_updates
        end
      else
        raise ActiveRecord::Rollback
      end
    end

    @image.update_index

    render partial: 'images/image_tags', layout: false, locals: { image: @image }
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def check_auth
    authorize! :update_metadata, @image
  end
end
