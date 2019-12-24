# frozen_string_literal: true

class Report < ApplicationRecord
  include FancySearchable
  include Indexable
  include UserAttributable
  include Notable

  resourcify

  belongs_to :user, inverse_of: :reports_made, optional: true
  belongs_to :admin, class_name: 'User', inverse_of: :managed_reports, optional: true
  belongs_to :reportable, polymorphic: true, optional: true

  validates :reason, presence: true

  def self.for_view
    includes(:admin, :reportable, user: :linked_tags)
  end
end
