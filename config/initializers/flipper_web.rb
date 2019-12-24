# frozen_string_literal: true

class CanAccessFlipper
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?

    current_user.can? :manage, Flipper
  end
end
