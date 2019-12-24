# frozen_string_literal: true

class StaticPage < ApplicationRecord
  has_many :versions, dependent: :delete_all

  validates :title, presence: true, uniqueness: true
  validates :slug,  presence: true, uniqueness: true
  validates :body,  presence: true

  attr_accessor :user

  after_save do
    versions.create!(user: user, title: title, slug: slug, body: body)
  end

  def to_param
    slug
  end
end
