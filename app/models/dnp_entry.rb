# frozen_string_literal: true

class DnpEntry < ApplicationRecord
  include AASM
  include Notable

  # Definitions
  DNPTYPES = Booru::CONFIG.dnp_types

  # Relations
  belongs_to :requesting_user, class_name: 'User', inverse_of: :dnp_entries, optional: true
  belongs_to :modifying_user, class_name: 'User', inverse_of: nil, optional: true
  belongs_to :tag, optional: true

  # Validations
  validates :reason, presence: true
  validates :dnp_type, presence: true, inclusion: { in: DNPTYPES.keys.map(&:to_s) }
  validates :tag_id, presence: true
  validates :conditions, presence: true, if: :requested_other?

  validate :can_request, on: :create

  # Determine if conditions should be required or not
  def requested_other?
    dnp_type == 'Other'
  end

  # Is the request in a state where it can be rescindable?
  def rescindable?
    %w[requested claimed listed].include? aasm_state
  end

  # For providing a JSON representation to the API
  def as_json(include_tag_details = false)
    obj = {
      id:         id,
      dnp_type:   dnp_type,
      conditions: conditions,
      reason:     hide_reason ? '' : reason,
      created_at: created_at
    }
    if include_tag_details
      obj[:tag_id] = tag_id
      obj[:tag_name] = tag.name
    end
    obj
  end

  # How many requests to list per admin page?
  def self.admin_listings_per_page
    50
  end

  # AASM State
  aasm do
    state :requested, initial: true
    state :claimed
    state :listed
    state :rescinded
    state :acknowledged
    state :closed

    event :claim do
      # Claim a DNP request (mod action)
      transitions from: [:requested], to: :claimed
    end
    event :list do
      # Displays a DNP request on the DNP list (mod action)
      transitions from: [:requested, :claimed], to: :listed
    end
    event :rescind do
      # Requests that a DNP list no longer be in effect (user action)
      # This doesn't go straight to closed, so stuff can be restored if possible
      transitions from: [:requested, :claimed, :listed], to: :rescinded
    end
    event :acknowledge do
      # Acknowledged a rescind request, basically a claim for rescinds
      transitions from: [:rescinded], to: :acknowledged
    end
    event :close do
      # Mark a DNP request as complete, and remove it from the list if necessary
      transitions from: [:requested, :claimed, :listed, :rescinded, :acknowledged], to: :closed
    end
  end

  private

  # Verify user can request a DNP for this tag
  def can_request
    errors.add(:tag_id, 'is not available for you to request a DNP for.') if !requesting_user.can?(:manage, DnpEntry) && !requesting_user.links.where(tag_id: tag_id).exists?
  end
end
