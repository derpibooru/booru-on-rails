# frozen_string_literal: true

class ConversationsController < ApplicationController
  include RateLimitable

  before_action :filter_banned_users, only: [:new, :create]
  before_action :require_user
  before_action :load_conversation, only: [:show]

  before_action -> { ratelimit 1, 5.minutes, 'Due to spam, you may only create a conversation once every 5 minutes.' }, unless: -> { current_user&.staff? }, only: [:new, :create]

  skip_authorization_check only: [:index]

  # GET /conversations
  def index
    @title = 'Messaging Center'

    @conversations = Conversation.where('(from_id = ? AND from_hidden = FALSE) OR (to_id = ? AND to_hidden = FALSE)', current_user.id, current_user.id)
    @conversations = @conversations.where('(from_id = ?) OR (to_id = ?)', params[:with].to_i, params[:with].to_i) if params[:with].present?
    @conversations = @conversations.order(last_message_at: :desc).page(params[:page]).per(25)
  end

  # GET /conversations/1
  def show
    @title = 'Viewing Conversation'

    authorize! :read, @conversation

    @conversation.from_read = true if @conversation.from == current_user
    @conversation.to_read   = true if @conversation.to   == current_user
    @conversation.save

    @messages = if current_user && current_user.messages_newest_first
      @conversation.messages.order(created_at: :desc)
    else
      @conversation.messages.order(created_at: :asc)
    end

    @messages = @messages.includes(:from).page(params[:page]).per(25)
    @message = @conversation.messages.build
  end

  # GET /conversations/new
  def new
    authorize! :create, Conversation
    @title = 'Create Conversation'

    @conversation = Conversation.new(title: params[:title], recipient: params[:recipient])
    @message = @conversation.messages.build
  end

  # POST /conversations
  def create
    authorize! :create, Conversation

    @conversation = current_user.started_conversations.build(conversation_params)
    @message = @conversation.messages.first
    @message.from = current_user
    @conversation.last_message_at = Time.zone.now

    if RetardFilter.is_1cjb(@message.body)
      ip_ban = SubnetBan.new(
        reason:        'Persistent ban evasion - please contact a moderator to have your account whitelisted',
        note:          'This ban was created automatically by DJDavid98\'s 1CJBFilter™',
        specification: request.remote_ip,
        until:         'moon',
        enabled:       true
      )
      ip_ban.banning_user = current_user
      ip_ban.save

      flash[:error] = 'You are banned.'
      redirect_back
    elsif @conversation.save
      flash[:notice] = 'Message successfully sent.'
      redirect_to conversation_path(@conversation)
    else
      render :new
    end
  end

  private

  def load_conversation
    @conversation = Conversation.find_by!(slug: params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:title, :recipient, messages_attributes: [:body])
  end
end
