# frozen_string_literal: true

class PollVote < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :option, class_name: 'PollOption', foreign_key: 'poll_option_id', inverse_of: :votes, optional: true
  has_one :poll, through: :option, foreign_key: 'poll_id'
  has_one :topic, through: :option

  # Make sure a user can only vote on the same option once
  validates :poll_option_id, uniqueness: { scope: :user_id }

  after_create :increase_counters
  after_destroy :decrease_counters

  def increase_counters
    option.increment! :vote_count
    poll.increment! :total_votes
  end

  def decrease_counters
    option.decrement! :vote_count
    poll.decrement! :total_votes
  end
end
