# frozen_string_literal: true

class Conversations::HidesController < ApplicationController
  before_action :require_user
  before_action :load_conversation
  before_action :check_auth

  def create
    @conversation.from_hidden = true if @conversation.from == current_user
    @conversation.to_hidden   = true if @conversation.to   == current_user
    @conversation.save

    respond_to do |format|
      format.html { redirect_to conversations_path, notice: 'Conversation hidden.' }
      format.json { head :ok }
    end
  end

  def destroy
    @conversation.from_hidden = false if @conversation.from == current_user
    @conversation.to_hidden   = false if @conversation.to   == current_user
    @conversation.save

    respond_to do |format|
      format.html { redirect_to conversation_path(@conversation), notice: 'Conversation restored.' }
      format.json { head :ok }
    end
  end

  private

  def load_conversation
    @conversation = Conversation.find_by!(slug: params[:conversation_id])
  end

  def check_auth
    authorize! :read, @conversation
  end
end
