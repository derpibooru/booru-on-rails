# frozen_string_literal: true

class User < ApplicationRecord
  include Reportable
  include QueryAssociable
  include Sluggable
  include Notable

  # Devise
  devise :registerable, :recoverable, :rememberable, :trackable, :validatable, :timeoutable, :lockable, :pwned_password
  devise :two_factor_authenticatable, otp_secret_encryption_key: Booru::CONFIG.settings[:devise_secret_key]
  devise :two_factor_backupable, otp_backup_code_length:     12,
                                 otp_number_of_backup_codes: 10

  set_slugged_field :name

  STAFF_ROLES = %w[assistant moderator admin].freeze
  ROLES = %w[user].concat(STAFF_ROLES).freeze
  SECONDARY_ROLES = ['Site Developer', 'System Administrator'].freeze

  # Allow mods to edit user profiles
  resourcify

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false, on: :create }
  validates :name, presence: true, uniqueness: { case_sensitive: false }, if: :will_save_change_to_name?
  validates :name, length: { maximum: 50, on: :create }
  validates :name, length: { maximum: 50 }, if: :will_save_change_to_name?
  validates :email, length: { maximum: 254, on: :create }
  validates :email, uniqueness: true
  validates :role, inclusion: { in: User::ROLES }
  validates :secondary_role, inclusion: { in: User::SECONDARY_ROLES }, allow_blank: true
  validates :images_per_page, numericality: { only_integer: true, greater_than_or_equal_to: Booru::CONFIG.settings[:min_images_per_page], less_than_or_equal_to: Booru::CONFIG.settings[:max_images_per_page] }
  validates :comments_per_page, numericality: { only_integer: true, greater_than_or_equal_to: Booru::CONFIG.settings[:min_comments_per_page], less_than_or_equal_to: Booru::CONFIG.settings[:max_comments_per_page] }
  validates :theme, inclusion: { in: $themes, message: 'must be one of the available themes' }
  validates :description, length: { maximum: 10_000 }
  validates :personal_title, length: { maximum: 24 }
  validates :personal_title, format: { without: /site|admin|moderator|assistant|developer|\p{C}/i }
  validate :self_deletion_validation
  validates_with ImageQueryValidator, fields: [:watched_images_query_str, :watched_images_exclude_str]

  ALLOWED_PARAMETERS = [
    :name,
    :email,
    :password,
    :password_confirmation,
    :remember_me,
    :description,
    :personal_title,
    :watched_tag_list,
    :show_sidebar_and_watched_images,
    :images_per_page,
    :show_large_thumbnails,
    :fancy_tag_field_on_upload,
    :fancy_tag_field_on_edit,
    :autorefresh_by_default,
    :anonymous_by_default,
    :scale_large_images,
    :comments_newest_first,
    :comments_always_jump_to_last,
    :comments_per_page,
    :fancy_tag_field_in_settings,
    :uploaded_avatar,
    :remove_avatar,
    :watch_on_reply,
    :watch_on_upload,
    :messages_newest_first,
    :watch_on_new_topic,
    :theme,
    :watched_images_query_str,
    :no_spoilered_in_watched,
    :watched_images_exclude_str,
    :use_centered_layout,
    :hide_vote_counts,
    :otp_secret
  ].freeze

  ALLOWED_PARAMETERS_BANNED = ALLOWED_PARAMETERS - [:uploaded_avatar, :remove_avatar, :name]

  file :avatar,
    store_dir:  Booru::CONFIG.settings[:avatars_file_path],
    url_prefix: Booru::CONFIG.settings[:avatars_url_prefix]

  file_validator :avatar,
    validator: :image_validator,
    mime:      %w[image/png image/jpeg image/gif],
    size:      0..300.kilobytes,
    width:     0..1000,
    height:    0..1000

  # Relations
  has_many :images
  has_many :comments
  has_many :started_conversations, inverse_of: :from, class_name: 'Conversation', foreign_key: 'from_id'
  has_many :received_conversations, inverse_of: :to, class_name: 'Conversation', foreign_key: 'to_id'
  has_many :deleted_images, class_name: 'Image'
  has_many :reports_made, inverse_of: :user, foreign_key: :user_id, class_name: 'Report'
  has_many :managed_reports, inverse_of: :admin, foreign_key: :admin_id, class_name: 'Report'
  has_many :donations
  has_many :bans, class_name: 'UserBan', inverse_of: :user
  has_many :user_bans_enacted, class_name: 'UserBan', inverse_of: :banning_user
  has_many :subnet_bans_enacted, class_name: 'SubnetBan', inverse_of: :banning_user
  has_many :fingerprint_bans_enacted, class_name: 'FingerprintBan', inverse_of: :banning_user
  has_many :topics
  has_many :posts
  has_many :created_notifications, inverse_of: :user, validate: false, class_name: 'Notification'
  has_many :awards_given, inverse_of: :awarded_by, class_name: 'BadgeAward'
  has_many :awards, class_name: 'BadgeAward', inverse_of: :user
  has_many :links, class_name: 'UserLink', inverse_of: :user
  has_many :verified_links, -> { verified }, class_name: 'UserLink', inverse_of: :user
  has_many :deleted_users, class_name: 'User', inverse_of: :deleted_by_user
  has_many :filters
  has_many :unread_notifications
  has_many :notifications, -> { includes(:actor, :actor_child) }, through: :unread_notifications
  has_many :user_ips, validate: false
  has_many :user_fingerprints, validate: false
  has_many :statistics, class_name: 'UserStatistics', inverse_of: :user
  has_many :galleries, -> { order updated_at: :desc }, foreign_key: :creator_id, inverse_of: :creator
  has_many :dnp_entries, class_name: 'DnpEntry', inverse_of: :requesting_user
  has_many :name_changes, -> { order(:created_at) }, class_name: 'UserNameChange', inverse_of: :user
  has_many :poll_votes, dependent: :destroy, inverse_of: :user
  has_many :linked_tags, -> { distinct }, class_name: 'Tag', through: :verified_links, source: 'tag'
  has_many :channel_subscriptions, class_name: 'Channel::Subscription'
  has_many :forum_subscriptions, class_name: 'Forum::Subscription'
  has_many :gallery_subscriptions, class_name: 'Gallery::Subscription'
  has_many :image_subscriptions, class_name: 'Image::Subscription'
  has_many :topic_subscriptions, class_name: 'Topic::Subscription'
  has_many :static_page_versions, class_name: 'StaticPage::Version'
  has_many :features, class_name: 'Image::Feature'

  has_one :commission

  has_array_field :watched_tags, Tag
  has_array_field :recent_filters, Filter

  has_tag_proxy on: :watched_tag_ids, name: :watched_tag_list

  belongs_to :current_filter, class_name: 'Filter', inverse_of: :current_users, validate: false, optional: true
  belongs_to :deleted_by_user, class_name: 'User', inverse_of: :deleted_users, optional: true

  # Custom roles
  rolify

  before_destroy do |u|
    # Administrator considerations.
    u.deleted_users.update_all(deleted_by: nil)
    u.managed_reports.update_all(admin: nil)
  end

  # Be able to call can? directly from user
  delegate :can?, :cannot?, to: :ability

  def ability
    @ability ||= Ability.new(self)
  end

  def add_stat(stat_name, value)
    stat = UserStatistics.find_or_initialize_by(day: Time.zone.now.to_i_timestamp, user_id: id)
    stat.send("#{stat_name}=", stat.send(stat_name) + value)
    stat.save!
    update_columns("#{stat_name}_count" => send("#{stat_name}_count") + value)
  end

  def inc_stat(stat_name)
    add_stat(stat_name, 1)
  end

  def dec_stat(stat_name)
    add_stat(stat_name, -1)
  end

  def last_90_days(stat_name)
    now = Time.zone.now.to_i_timestamp
    @last90 ||= statistics.where('day > ?', now - 89).to_a
    # Inserts zero values where days are missing.
    data_for_stat = Hash[(now - 89..now).map { |k| [k, 0] }]
    @last90.each { |s| data_for_stat[s.day] = s.send(stat_name) }

    data_for_stat.values
  end

  after_save :reset_token_if_blank!

  def reset_token_if_blank!
    reset_authentication_token! if authentication_token.blank?
  end

  def reset_api_token!
    update_attribute :authentication_token, nil
    reset_token_if_blank!
  end

  def unsubscribe_restricted_actors
    level  = Forum.access_level_for(role)
    forums = Forum.where.not(access_level: level)

    forum_subscriptions.where(forum: forums).delete_all
    topic_subscriptions.where(topic: Topic.where(forum: forums)).delete_all
  end

  # Scrub name for spacing and Unicode hijinks and set slug before validation
  # fires off (to prevent unnecessary collision complaints).
  before_validation :scrub_name!, :set_slug
  def scrub_name!
    self.name =
      name
      .unicode_normalize(:nfc)
      .strip
      .gsub(/[\p{Space}\ ]\z/, '')
      .gsub(/\p{C}/, '')
      .gsub(/\p{Space}/, ' ')
      .tr("\u3164", ' ')
      .tr("\u115F", ' ')
      .tr("\u1160", ' ')
      .tr("\uFFA0", ' ')
  end

  after_commit(on: :update) do
    ReindexUserRelationsJob.perform_later(id) if previous_changes[:name]
  end

  def potential_aliases
    @potential_aliases ||= begin
      matches = []

      ip_matches = User.where(id: UserIp.where(ip: user_ips.select(:ip)).select(:user_id)).to_a
      fp_matches = User.where(id: UserFingerprint.where(fingerprint: user_fingerprints.select(:fingerprint)).select(:user_id)).to_a

      ip_matches.delete_if { |u| u.id == id }
      fp_matches.delete_if { |u| u.id == id }

      both_matches = ip_matches & fp_matches
      ip_matches -= both_matches
      fp_matches -= both_matches

      both_matches.uniq.compact.each do |u|
        matches += [['IP ADDRESS + FINGERPRINT', u]]
      end
      ip_matches.uniq.compact.each do |u|
        matches += [['IP ADDRESS', u]]
      end
      fp_matches.uniq.compact.each do |u|
        matches += [['FINGERPRINT', u]]
      end

      matches = matches.uniq.compact
    end
  end

  def watched_images_query
    User.normalize_user_query_program(watched_images_query_str)
  end

  def watched_images_exclude_query
    User.normalize_user_query_program(watched_images_exclude_str)
  end

  def watching_images?
    !watched_tag_ids.empty? || watched_images_query_str.present?
  end

  def show_advertisements?
    !hide_advertisements
  end

  def as_json(*)
    {
      id:            id,
      name:          name,
      slug:          slug,
      role:          staff? ? role : 'user',
      description:   description,
      avatar_url:    avatar.present? ? uploaded_avatar.url : nil,
      created_at:    created_at,
      comment_count: comments_posted_count,
      uploads_count: uploads_count,
      post_count:    forum_posts_count,
      topic_count:   topic_count,
      links:         links.verified.where(public: true),
      awards:        awards
    }
  end

  def set_or_unset_role(do_set, *args)
    func = (do_set ? :add_role : :remove_role)
    method(func).call(*args)
  end

  # devise backwards compat hack - see https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
  before_save :ensure_authentication_token

  def ensure_authentication_token
    self.authentication_token = generate_authentication_token if authentication_token.blank?
  end

  # overriding dirty tracking since it gets it wrong
  def email_changed?
    return true if new_record?

    if changed.include?(:email)
      return true if email_was.strip != email.strip
    end
    false
  end

  before_create :set_default_filter!

  def set_default_filter!
    return nil unless Filter.default_filter

    set_filter!(Filter.default_filter)
  end

  def set_filter!(filter)
    if filter != current_filter
      current_filter.on_lost_user if current_filter
      self.current_filter = filter
      filter.on_gained_user
      recent_filter_ids.unshift filter.id
      self.recent_filter_ids = recent_filter_ids.uniq[0..10] # trim the list
      save! if persisted?
    end
    filter
  end

  def set_spoiler!(type)
    # check if one of the four allowed strings
    if %w[static click hover off].include? type
      self.spoiler_type = type
      save!
    end
  end

  def soft_delete!(deleter = nil)
    self.deleted_at = Time.zone.now
    self.deleted_by_user = deleter
    save!
  end

  def soft_undelete!
    self.deleted_at = self.deleted_by_user = nil
    save!
  end

  def active_for_authentication?
    super && deleted_at.nil?
  end

  def staff?
    @staff ||= User::STAFF_ROLES.include? role
  end

  def can_act_as?(role)
    User::ROLES.index(self.role) >= User::ROLES.index(role)
  end

  def currently_banned?
    bans.where('valid_until >= ?', Time.zone.now).present?
  end

  def previously_banned?
    bans.present?
  end

  def previous_usernames
    name_changes.empty? ? nil : name_changes.each.pluck(:name)
  end

  def recently_renamed?
    ((Time.zone.now - last_renamed_at) < 90.days) || ((Time.zone.now - created_at) < 90.days)
  end

  def clear_recent_filters!
    self.recent_filter_ids = [current_filter_id]
    save!
  end

  #
  # Set badges for donors.
  #
  def set_donation_badges!
    monthly = Booru::CONFIG.badges[:monthly]
    all_time = Booru::CONFIG.badges[:all_time]

    # Count our cash
    last_30d_donation_total = donations.where('created_at > ?', Time.zone.now - 30.days).pluck(:amount).sum
    all_time_donation_total = donations.pluck(:amount).sum

    # Load all Donor badge IDs
    donor_badge_ids = monthly.values + all_time.values

    # Get an array of badge IDs this user already has, so we know which to remove
    current_donor_badge_awards = awards.where(badge_id: donor_badge_ids).pluck(:badge_id)

    # Map amounts into badge IDs
    badges_to_award = [
      monthly.detect { |amt, _| last_30d_donation_total >= amt }.second,
      all_time.detect { |amt, _| all_time_donation_total >= amt }.second
    ].compact.uniq

    current_donor_badge_awards.each do |badge_id|
      awards.where(badge_id: badge_id).delete_all
    end

    # Actually add badges
    badges_to_award.each do |badge_id|
      next if awards.find_by(badge_id: badge_id)

      awards.create!(awarded_by: self, awarded_on: Time.zone.now, reason: "Supporting #{I18n.t('booru.name')}", badge_id: badge_id)
    end
  end

  def self_deletion_validation
    errors.add(:deleted_by_user_id, 'User cannot delete self.') if self == deleted_by_user
  end

  def generate_otp_secret!
    self.otp_secret = User.generate_otp_secret.upcase
  end

  def twofactor_qr_uri
    issuer = I18n.t('booru.name')
    label = "#{issuer}:#{email}"
    otp_provisioning_uri(label, issuer: issuer)
  end

  def twofactor_qr_image
    RQRCode::QRCode.new(twofactor_qr_uri).as_png(size: 350).to_data_url
  end

  def to_param
    slug
  end

  # Overrides for devise-pwned_password gem to allow toggling with Flipper
  alias vendor_password_pwned? password_pwned?
  def password_pwned?(password)
    return vendor_password_pwned?(password) if $flipper.enabled? :pwned_password_check

    false
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.find_by(authentication_token: token)
    end
  end

  protected

  # We don't need to be confirmed
  def confirmation_required?
    false
  end

  # Always deliver via ActiveJob
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
