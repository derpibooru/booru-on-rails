# frozen_string_literal: true

class Admin::PollsController < ApplicationController
  before_action :check_auth
  before_action :load_poll

  def edit
    @title = "Editing Poll: #{@poll.title}"
  end

  def destroy
    Hider.new(@poll, user: current_user, reason: params[:deletion_reason]).save
    HidableLogger.log(@poll, 'Deleted', current_user.name, params[:deletion_reason])

    redirect_to @poll.link_to_route, notice: t('polls.destroy.success', id: @poll.id)
  end

  def update
    @poll.topic.update(poll_attributes: poll_params)

    respond_to do |format|
      format.html { redirect_to @poll.link_to_route }
      format.json { render head: :ok }
    end
  end

  private

  def check_auth
    authorize! :manage, Poll
  end

  def load_poll
    @poll = Poll.find(params[:id])
  end

  def poll_params
    params.require(:poll).permit(*Poll::POLL_ATTRIBUTES_EDIT)
  end

  def vote_params
    params.permit(:user_id, :poll_option_id)
  end
end
