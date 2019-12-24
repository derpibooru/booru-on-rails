# frozen_string_literal: true

module AnonUserAttributable
  extend ActiveSupport::Concern
  include UserAttributable

  def user_visible?
    super && !anonymous
  end
end
