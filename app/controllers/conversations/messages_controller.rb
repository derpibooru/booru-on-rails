# frozen_string_literal: true

class Conversations::MessagesController < ApplicationController
  before_action :filter_banned_users, only: [:new, :create]
  before_action :load_conversation
  before_action :require_user

  def new
    authorize! :read, @conversation

    @message = @conversation.messages.build
  end

  def create
    authorize! :read, @conversation

    @message = @conversation.messages.build(message_params)
    @message.from = current_user

    if @message.save
      flash[:notice] = 'Message successfully sent.'

      if current_user.messages_newest_first
        redirect_to conversation_path(@conversation)
      else
        # Last page.
        page = (@conversation.messages.count / 25.0).ceil
        redirect_to conversation_path(@conversation, page: page)
      end
    else
      render :new
    end
  end

  private

  def load_conversation
    @conversation = Conversation.find_by!(slug: params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
