# frozen_string_literal: true

class Images::VotesController < ApplicationController
  before_action :load_image
  before_action :load_user
  before_action :check_auth

  def destroy
    @image.votes.where(user: @user).destroy_all
    @image.update_index

    redirect_to short_image_path(@image)
  end

  private

  def load_image
    @image = Image.find(params[:image_id])
  end

  def load_user
    @user = User.find(params[:id])
  end

  def check_auth
    authorize! :tamper_votes, @image
  end
end
