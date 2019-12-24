# frozen_string_literal: true

class CannotAccessWebsite
  if Rails.env.production?
    def self.matches?(request)
      request.remote_ip == '127.0.0.1' && !request.env['warden'].authenticated?
    end
  else
    def self.matches?(_request)
      false
    end
  end
end
