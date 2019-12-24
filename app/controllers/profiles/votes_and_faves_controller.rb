# frozen_string_literal: true

class Profiles::VotesAndFavesController < ApplicationController
  before_action :load_user
  before_action :check_auth

  # DELETE /profiles/:user_id/votes_and_faves
  # Remove all of a user's votes and favorites
  def destroy
    UserUnvoteJob.perform_later(@user.id, true)
    UserLogger.log('Votes wiped', @user, current_user)
    redirect_to profile_path(@user.slug), notice: 'Started vote wipe'
  end

  private

  def load_user
    @user = User.find_by_slug_or_id(params[:profile_id])
    raise ActiveRecord::RecordNotFound unless @user
  end

  def check_auth
    authorize! :tamper_votes, @user
  end
end
