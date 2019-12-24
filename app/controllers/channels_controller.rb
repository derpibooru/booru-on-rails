# frozen_string_literal: true

class ChannelsController < ApplicationController
  before_action :check_auth, except: [:show, :index]
  before_action :load_channel, only: [:show, :edit, :update, :destroy]

  skip_authorization_check only: [:index, :show]

  def index
    @nsfw = (cookies[:chan_nsfw] == 'true')
    @title = 'Livestreams'
    @channels = if params[:cq].present?
      ChannelQuery.live_and_static_sorted(@nsfw)
                  .joins(:associated_artist_tag)
                  .where('(title ILIKE ?) OR (short_name ILIKE ?) or (tags.name ILIKE ?)', params[:cq] + '%', params[:cq] + '%', '%' + params[:cq] + '%')
    else
      ChannelQuery.live_and_static_sorted(@nsfw)
    end.page(params[:page]).per(25)
  end

  def show
    Notification.mark_all_read(@channel, current_user) if current_user
    redirect_to @channel.url
  end

  def new
    @title = 'Create Livestream Channel'
    @channel = Channel.new
  end

  def edit
    @title = "Editing Livestream for #{@channel.artist_tag}"
  end

  def create
    @channel = Channel.get_subclass(params[:channel][:url]).new(channel_params)
    c = Channel.where(type: @channel.type).find_by(short_name: @channel.short_name)
    if c.present? # Channel exists, go to it.
      redirect_to channels_path, notice: 'Channel already exists'
    elsif @channel.save # Channel doesn't exist, create it.
      redirect_to channels_path, notice: 'Channel created successfully'
    else
      render action: 'new', error: 'Whoops, something went wrong - look at the form below for more info'
    end
  end

  def update
    if @channel.update(channel_params)
      redirect_to channels_path, notice: 'Channel updated'
    else
      render action: 'new', error: 'Whoops, something went wrong - look at the form below for more info'
    end
  end

  def destroy
    @channel.destroy!
    redirect_to channels_path, notice: 'Channel deleted'
  end

  private

  def check_auth
    authorize! :manage, Channel
  end

  def load_channel
    @channel = Channel.find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(:url, :artist_tag, :nsfw)
  end
end
