# frozen_string_literal: true

require 'securerandom'

class UserLink < ApplicationRecord
  include AASM
  resourcify

  validates :user_id, presence: true
  validates :uri, presence: true
  validates :uri, format: URI.regexp(%w[http https])
  validates :tag_id,
            uniqueness: {
              scope:      [:user_id, :uri],
              conditions: -> { where.not(aasm_state: 'rejected') },
              message:    ' and URL combo only allowed once per user'
            },
            on:         :create

  before_create do
    self.verification_code = "DERPI-LINKVALIDATION-#{SecureRandom.hex[0..9].upcase}"
    self.next_check_at = Time.zone.now + 2.minutes
    uri_obj = URI.parse(uri)
    self.hostname = uri_obj.host
    self.path = uri_obj.path
    UserLinkLogger.log('new', user)
  end

  belongs_to :user, optional: true
  belongs_to :tag, optional: true
  belongs_to :verified_by_user, class_name: 'User', inverse_of: nil, optional: true
  belongs_to :contacted_by_user, class_name: 'User', inverse_of: nil, optional: true

  aasm do
    state :unverified, initial: true
    state :link_verified
    state :contacted
    state :verified
    state :rejected
    event :mark_link_verified do
      transitions from: [:unverified], to: :link_verified
      before { UserLinkLogger.log('Link verified', user) }
    end
    event :mark_contacted do
      transitions from: [:unverified, :link_verified, :rejected], to: :contacted
    end
    event :mark_verified do
      transitions from: [:unverified, :contacted, :link_verified, :rejected], to: :verified
      after do
        # if link is public and one of the tags is an artist tag
        if public && tag&.namespace == 'artist'
          artist_badge_id = Booru::CONFIG.badges[:artist]
          # if the user doesn't have one already
          if !user.awards.find_by(badge_id: artist_badge_id) && Badge.find_by(id: artist_badge_id)
            award = user.awards.new
            award.awarded_by = verified_by_user
            award.awarded_on = Time.zone.now
            award.badge_id = artist_badge_id
            award.save!
          end
        end
      end
    end
    event :reject do
      transitions from: [:unverified, :contacted, :link_verified, :verified], to: :rejected
    end
  end

  def automatic_verify
    # Set our next check time according to how long we've been checking
    if (Time.zone.now - created_at) > 604_800
      # 7 days
      update_columns(next_check_at: Time.zone.now + 7.days)
    elsif (Time.zone.now - created_at) > 259_200
      # 3 days
      update_columns(next_check_at: Time.zone.now + 12.hours)
    elsif (Time.zone.now - created_at) > 3600
      # 1 hour
      update_columns(next_check_at: Time.zone.now + 1.hour)
    else
      # anything more recent, check regularly
      update_columns(next_check_at: Time.zone.now + 2.minutes)
    end
    # We shouldn't ever get here, but just in case..
    return false unless may_mark_link_verified?

    # Really simple check yonder:
    response = RestClient::Request.execute(url: uri.to_s, method: :get, timeout: 5, open_timeout: 3)
    if response.include?(verification_code)
      # Cave Johnson, we're done here
      self.next_check_at = nil
      mark_link_verified!
    end
  rescue StandardError
    false
  end

  def self.check_all_pending
    UserLink.unverified.where('next_check_at < ?', Time.zone.now).find_each(&:automatic_verify)
  end

  def tag_name
    Tag.find_by(id: tag_id)&.name
  end

  def tag_name=(name)
    self.tag = Tag.find_by(name: name)
  end

  def as_json(*)
    {
      user_id:    user_id,
      created_at: created_at,
      state:      aasm_state,
      tag_id:     tag_id
    }
  end
end
