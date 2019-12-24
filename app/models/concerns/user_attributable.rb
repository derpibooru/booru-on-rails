# frozen_string_literal: true

require 'anony_hash'

# Capture request attributes for models that include this concern
# by applying the hash provided by +request_attributes+ controller method.
module UserAttributable
  extend ActiveSupport::Concern
  include AnonyHash

  included do
    belongs_to :user, validate: false, optional: true
  end

  def best_user_identifier
    [self&.user_id, self&.fingerprint, self&.ip].detect(&:present?)
  end

  def author(reveal_anon = false)
    author_text = anonymous_user_and_hash(self)
    if user_visible?
      author_text = user.name
    elsif user && reveal_anon
      author_text = user.name + " (##{get_anony_hash(self)}, hidden)"
    elsif ip == '127.1.1.1'
      author_text = 'System'
    end
    author_text
  end

  def user_visible?
    !user.nil?
  end
end
