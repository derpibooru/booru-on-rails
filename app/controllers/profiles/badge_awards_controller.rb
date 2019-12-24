# frozen_string_literal: true

class Profiles::BadgeAwardsController < ApplicationController
  before_action :load_user, only: [:new, :create]
  before_action :load_award, only: [:edit, :update, :destroy]
  before_action :check_auth

  def new
    @award = @user.awards.build
    @title = "Create Badge: #{@user.name}"
  end

  def create
    @award = @user.awards.new(awarded_by: current_user,
                              awarded_on: Time.zone.now,
                              badge:      Badge.find(params[:badge_id]))
    @award.assign_attributes(badge_award_params)
    @award.save!

    BadgeLogger.log(@award.badge.title, 'awarded', current_user, @user)
    redirect_to profile_path(@user.slug), notice: 'Badge was successfully awarded.'
  end

  def edit
    @title = "Editing Badge: #{@award.badge_name.presence || @award.badge.title}"
  end

  def update
    @award.update! badge_award_params

    BadgeLogger.log(@award.badge.title, 'updated', current_user, @user)
    redirect_to profile_path(@user.slug), notice: 'Badge was successfully updated.'
  end

  def destroy
    @award.destroy!

    BadgeLogger.log(@award.badge.title, 'removed', current_user, @user)
    redirect_to profile_path(@user.slug), notice: 'Award was successfully destroyed. By cruel and unusual means.'
  end

  private

  def check_auth
    authorize! :award, Badge
  end

  def load_user
    @user = User.find_by_slug_or_id(params[:profile_id])
    raise ActiveRecord::RecordNotFound unless @user
  end

  def load_award
    @award = BadgeAward.find(params[:id])
    @user = @award.user
  end

  def badge_award_params
    params.require(:badge_award).permit(:reason, :label, :badge_name)
  end
end
