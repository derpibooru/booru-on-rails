# frozen_string_literal: true

class BotsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'bots'
  end

  def unsubscribed
    stop_all_streams
  end
end
