# frozen_string_literal: true

class Conversations::HideBatchesController < ApplicationController
  before_action :require_user
  before_action :load_conversations
  before_action :check_auth

  def create
    @conversations.where(from_id: current_user.id).update_all(from_hidden: true)
    @conversations.where(to_id: current_user.id).update_all(to_hidden: true)

    respond_to do |format|
      format.html { redirect_to conversations_path, notice: 'Conversation(s) hidden.' }
      format.json { head :ok }
    end
  end

  private

  def load_conversations
    @conversations = Conversation.where(slug: params[:ids])
  end

  def check_auth
    authorize! :bulk_update, Conversation
  end
end
