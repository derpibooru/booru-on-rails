# frozen_string_literal: true

class Poll < ApplicationRecord
  include Hidable

  resourcify

  belongs_to :user, optional: true
  belongs_to :topic, optional: true
  has_many :options, class_name: 'PollOption', inverse_of: :poll

  attr_accessor :initialized_at

  validates :title, presence: true, length: { maximum: 140 }
  validates :active_until, presence: true
  validates :vote_method, presence: true, length: { maximum: 8 }, inclusion: { in: %w[single multiple] }
  validate :require_two_options
  validate :minimum_run_time, on: :create

  validates_associated :options

  before_validation :set_default_end_date

  POLL_ATTRIBUTES = [:title, :until, :vote_method, options_attributes: [:label]].freeze
  POLL_ATTRIBUTES_EDIT = [:id, *POLL_ATTRIBUTES, options_attributes: [:id, :label, :_destroy]].freeze

  def self.max_option_count
    20
  end

  def self.min_run_time_hours
    24
  end

  accepts_nested_attributes_for :options, limit: max_option_count, reject_if: :all_blank, allow_destroy: true

  def until=(sometime)
    self.active_until = Chronic.parse(sometime)
  end

  def until
    active_until.to_s
  end

  def active?
    !hidden_from_users && active_until > Time.zone.now
  end

  def options_ids
    options.pluck :id
  end

  def votes_of(user)
    return [] if !user

    PollVote.where(user: user, poll_option_id: options_ids).all
  end

  delegate :link_to_route, to: :topic

  def visible_to?(user)
    !hidden_from_users || can_see_when_hidden?(user)
  end

  def can_see_when_hidden?(user)
    user && user.can?(:manage, Poll)
  end

  def ranked_options
    case vote_method
    when 'multiple', 'single'
      options.top
    else
      raise "Unhandled vote_method in ranked_options: #{vote_method}"
    end
  end

  def winning_option_id
    case vote_method
    when 'single', 'multiple'
      options.max_by(&:vote_count).id
    else
      raise "Unhandled vote_method in winning_option: #{vote_method}"
    end
  end

  def multiple_choice
    vote_method == 'multiple'
  end

  private

  def require_two_options
    errors.add(:options, 'must contain at least two') if options.size < 2
  end

  def minimum_run_time
    duration = active_until.to_i - (initialized_at || Time.zone.now.to_i)
    min_run_time = Poll.min_run_time_hours
    if duration.seconds < min_run_time.hour
      error_time = "#{min_run_time} hour".pluralize(min_run_time)
      errors.add(:active_until, "cannot be less than #{error_time} away")
    end
  end

  def set_default_end_date
    self.active_until ||= Chronic.parse('2 weeks from now')
  end
end
