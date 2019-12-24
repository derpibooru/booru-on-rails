# frozen_string_literal: true

class LoggerBase
  def self.livefeed_send(string)
    ActionCable.server.broadcast 'bots', livefeed: string
  end

  def self.modfeed_send(string)
    ActionCable.server.broadcast 'bots', modfeed: string
  end

  def self.sanitize_newlines(string)
    string.gsub("\n", ' | ').delete("\r")
  end
end
