# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = if request.params[:key] == Booru::CONFIG.settings[:bot_api_key]
        'BOT'
      else
        find_verified_user
      end
    end

    protected

    # this checks whether a user is authenticated with devise
    def find_verified_user
      if (user = env['warden'].user)
        user
      else
        reject_unauthorized_connection
      end
    end
  end
end
