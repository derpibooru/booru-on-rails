# frozen_string_literal: true

class Hider
  def initialize(component, user: nil, reason:)
    @component = component
    @user = user
    @reason = reason
  end

  def save
    if !@component.hidden_from_users
      before_save
      @component.update(hidden_from_users: true, deleted_by_id: @user&.id, deletion_reason: @reason)
      after_save
    end
  end

  def before_save
  end

  def after_save
  end
end
