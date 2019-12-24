# frozen_string_literal: true

class PollOption < ApplicationRecord
  belongs_to :poll, optional: true
  has_many :votes, class_name: 'PollVote'
  has_many :users, through: :votes

  default_scope { order(id: :asc) }
  scope :top, -> { unscope(:order).order(vote_count: :desc, id: :asc) }

  validates :label, presence: true, length: { maximum: 80 }
  validates_db_uniqueness_of :label, scope: :poll_id, message: 'must be unique'

  before_validation :squish_label

  def percent_of_total(total = poll.total_votes)
    return 0 if total == 0

    format('%<percent>g%%', percent: (vote_count.to_f / total * 100).round(2))
  end

  private

  def squish_label
    self.label = label.squish
  end
end
