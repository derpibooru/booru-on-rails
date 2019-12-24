# frozen_string_literal: true

class StaffPresenter
  # Users with any special role
  def users
    @users ||= User.where(role: %w[admin moderator assistant]).order(name: :asc)
  end

  # Administrators
  def admins
    @admins ||= users.select { |u| u.role == 'admin' }
  end

  # Developers
  def developers
    @developers ||= users.select { |u| u.role != 'admin' && u.secondary_role.present? }
  end

  # Moderators
  def moderators
    @moderators ||= users.select { |u| u.role == 'moderator' && u.secondary_role.blank? }
  end

  # Assistants
  def assistants
    @assistants ||= users.select { |u| u.role == 'assistant' && u.secondary_role.blank? }
  end

  # All staff categories.
  #
  # @return [Hash<String, Array<User>>]
  def categories
    {
      'Administrators' => admins,
      'Technical Team' => developers,
      'Moderators'     => moderators,
      'Assistants'     => assistants
    }
  end

  # JSON representation of staff page.
  def as_json
    rendered = Rails.cache.fetch('staff-v1', expires_in: 45.minutes) do
      {
        administrators: admins.as_json,
        developers:     developers.as_json,
        moderators:     moderators.as_json,
        assistants:     assistants.as_json
      }
    end

    {
      staff: rendered
    }
  end
end
