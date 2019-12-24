# frozen_string_literal: true

module Notable
  extend ActiveSupport::Concern

  included do |_notable|
    has_many :mod_notes, validate: false, as: :notable
    before_destroy do |n|
      n.mod_notes.update_all(notable_id: nil)
    end
  end
end
