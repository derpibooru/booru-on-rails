# frozen_string_literal: true

class Ban < ApplicationRecord
  self.abstract_class = true

  validates :reason, :valid_until, presence: true

  has_paper_trail on: [:update, :destroy]

  before_create :generate_ban_id

  def until=(sometime)
    sometime = '1000 years from now' if sometime == 'moon'
    self.valid_until = Chronic.parse(sometime)
  end

  def until
    valid_until.to_s
  end

  def active?
    valid_until > Time.zone.now && enabled
  end

  def self.valid
    where('valid_until > ?', Time.zone.now)
  end

  def generate_ban_id
    self.generated_ban_id = "#{id_prefix}#{SecureRandom.hex(3).upcase}"
  end

  private

  def id_prefix
  end
end
