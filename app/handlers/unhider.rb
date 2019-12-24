# frozen_string_literal: true

class Unhider
  def initialize(component)
    @component = component
  end

  def save
    if @component.hidden_from_users
      before_save
      @component.update(hidden_from_users: false, deleted_by_id: nil, deletion_reason: '')
      after_save
    end
  end

  def before_save
  end

  def after_save
  end
end
