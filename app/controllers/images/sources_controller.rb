# frozen_string_literal: true

class Images::SourcesController < ApplicationController
  include RateLimitable

  before_action :filter_banned_users
  before_action :load_image
  before_action :check_auth

  before_action -> { ratelimit 1, 5.seconds, t('booru.errors.metadata_flooding', seconds: 5) }, unless: -> { current_user&.staff? }

  def update
    if !captcha_verified?
      @image.errors[:base] << t('images.update_metadata.errors.captcha_unverified')
      render partial: 'images/source', layout: false, locals: { image: @image }
      return
    end

    @image.with_lock do
      @image.source_url = params[:image][:source_url].strip if params[:image][:source_url].present?

      if @image.save
        if @image.previous_changes[:source_url]
          SourceChange.add_to_img(@image, current_user, request)
          SourceChangeLogger.log(@image, current_user, @image.previous_changes[:source_url].first)
        end
      else
        raise ActiveRecord::Rollback
      end
    end

    @image.update_index

    render partial: 'images/source', layout: false, locals: { image: @image }
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def check_auth
    authorize! :update_metadata, @image
  end
end
