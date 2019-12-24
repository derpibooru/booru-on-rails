# frozen_string_literal: true

class CanAccessJobs
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?

    current_user.can? :manage, ActiveJob
  end
end
