# frozen_string_literal: true

class Admin::Polls::VotesController < ApplicationController
  before_action :check_auth
  before_action :load_vote

  def destroy
    @vote.destroy!

    redirect_to @poll.link_to_route, notice: t('poll_votes.destroy.success', id: @poll)
  end

  private

  def check_auth
    authorize! :manage, Poll
  end

  def load_poll
    @poll = Poll.find(params[:poll_id])
    @vote = @poll.votes.find(params[:id])
  end
end
