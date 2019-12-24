# frozen_string_literal: true

class StaticPage::Version < ApplicationRecord
  belongs_to :user
  belongs_to :static_page

  validates :title, presence: true
  validates :slug,  presence: true
  validates :body,  presence: true
end
