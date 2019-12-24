# frozen_string_literal: true

class PollVotesController < ApplicationController
  before_action :require_user
  before_action :load_poll

  def create
    authorize! :create, PollVote

    return redirect_back(flash: { error: 'This poll has concluded; votes are no longer accepted.' }) unless @poll.active?

    return redirect_back(flash: { error: 'You already voted on this poll.' }) if @poll.votes_of(current_user).any?

    option_ids = if @poll.multiple_choice
      params[:poll_option_ids]
    else
      [params[:poll_option_id]]
    end
    options = PollOption.where(id: option_ids, poll_id: @poll.id)
    if options.empty? || options.length != option_ids.length
      redirect_back(flash: { error: 'You must select at least one option.' })
    else
      PollOption.transaction do
        options.each do |option|
          option.votes.create(user_id: current_user.id)
        end
      end
      redirect_back(flash: { notice: 'Your vote has been recorded.' })
    end
  end

  private

  def load_poll
    @poll = Poll.find(params[:poll_id])
  end
end
