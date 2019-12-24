# frozen_string_literal: true

class Image < ApplicationRecord
  include Hidable
  include Reportable
  include FancySearchable
  include Indexable
  include AnonUserAttributable

  resourcify

  belongs_to :user, inverse_of: :images, optional: true
  belongs_to :deleted_by, class_name: 'User', inverse_of: :deleted_images, optional: true

  has_many :comments, validate: false
  has_many :tag_changes, validate: false, dependent: :delete_all
  has_many :source_changes, validate: false, dependent: :delete_all
  has_many :duplicate_reports
  has_many :notifications, inverse_of: :actor
  has_many :gallery_interactions
  has_many :galleries, through: :gallery_interactions
  has_many :mod_notes, as: :noteable
  has_many :subscriptions, dependent: :delete_all
  has_many :subscribers, through: :subscriptions, source: :user
  has_many :features
  has_many :faves, class_name: 'Image::Fave', validate: false
  has_many :hides, validate: false
  has_many :votes, validate: false
  has_many :taggings, validate: false
  has_many :tags, through: :taggings, validate: false
  has_one :intensity

  has_many :upvotes, -> { where(up: true) }, class_name: 'Image::Vote', inverse_of: false
  has_many :downvotes, -> { where(up: false) }, class_name: 'Image::Vote', inverse_of: false

  attr_accessor :tag_input, :tags_compare_against, :scraper_url, :scraper_cache, :disable_processing

  mount_uploader :image, ImageUploader

  validates :description, length: { maximum: Booru::CONFIG.settings[:max_comment_length] }
  validates :source_url, length: { maximum: Booru::CONFIG.settings[:max_image_url_length] }
  validates :hidden_from_users, presence: { if: :duplicate_id }
  validates :image, presence: { unless: :destroyed_content }
  validates_with DestroyOnlyIfHiddenValidator
  validates_with ImageHashDuplicationValidator, on: :create
  validates_with TagInputValidator, if: proc { |img| img.new_record? || img.tag_input.present? }

  before_save :record_tag_input, if: proc { |img| img.tag_input.present? }

  after_commit do |img|
    ProcessImageJob.perform_later(img.id) if img.image.previously_changed? && !img.disable_processing
  end

  before_create do |img|
    img.first_seen_at = img.created_at
  end

  before_destroy :clear_notifications!, unless: :hidden_from_users

  def add_tags(added_tags)
    @tag_input = (tags + added_tags).uniq.map(&:name).join(',')
  end

  def remove_tags(removed_tags)
    @tag_input = (tags - removed_tags).map(&:name).join(',')
  end

  def record_tag_input
    # Round up tags early so we aren't stuck in string land, use what the client saw as tag list if possible
    input_tags = Tag.parse_tag_list(tag_input)
    tags_present = Tag.parse_tag_list(tags_compare_against || tag_list)
    # Clear input storage now that we've processed it
    @tag_input = @tags_compare_against = nil

    # Get the differences from what was there
    tags_to_remove = Tag.make_tags_from_names(tags_present - input_tags)
    tags_to_add = Tag.make_tags_from_names(input_tags - tags_present)

    # Add implications, hardcode for categorical ones
    tags_to_add.concat Tag.where(id: tags_to_add.flat_map(&:implied_tag_ids).uniq)
    tags_to_add << Tag.find_tag_by_name('oc') if tags_to_add.any? { |t| t.namespace == 'oc' }

    # Coalesce and deal with ratings
    desired_tags = ((tags - tags_to_remove) + tags_to_add).uniq
    desired_tags = Tag.make_tags_from_names(Tag.merge_ratings(desired_tags.map(&:name))).uniq

    # Store the ACTUAL changes that'll happen for things to refer to
    @tags_added = desired_tags - tags
    @tags_removed = tags - desired_tags

    # Actually change the tags
    tags.push(@tags_added)
    tags.delete(@tags_removed)

    # Cleanup
    add_ids = @tags_added.map(&:id)
    remove_ids = @tags_removed.map(&:id)
    if !hidden_from_users
      Tag.where(id: remove_ids).update_all 'images_count = images_count - 1'
      Tag.where(id: add_ids).update_all    'images_count = images_count + 1'
    end
    BulkIndexUpdateJob.perform_later 'Tag', (remove_ids + add_ids)

    nuke_tag_caches! if persisted?
    CommentTagsReindexJob.perform_later(id) if comments_count > 0
  end

  def tags_added
    @tags_added ||= []
  end

  def tags_removed
    @tags_removed ||= []
  end

  def tags_plus_aliased
    tags = Tag.arel_table
    Tag.where(tags[:id].in(tag_ids).or(tags[:aliased_tag_id].in(tag_ids)))
  end

  def clear_notifications!
    Notification.async_cleanup(self)
    nil
  end

  def file_type
    image_format&.upcase
  end

  def file_name(truncated = false)
    return id.to_s if truncated
    return file_name_cache if file_name_cache

    # Not set? Let's build.
    # Trunate filename to 150 characters, making room for the path + filename on Windows - https://stackoverflow.com/questions/265769/maximum-filename-length-in-ntfs-windows-xp-and-windows-vista
    fn = "#{id}__#{Tag.where(id: tag_ids).display_order.pluck(:slug).join('_')}".gsub('%2F', '').delete('/')[0..150].sub(/%\h?\z/, '') rescue id.to_s
    update_columns(file_name_cache: fn)
  end

  def source_url=(val)
    super(val) if val
  end

  def tag_list
    return '' if new_record?

    update_columns tag_list_cache: tags.order(name: :asc).pluck(:name).join(', ') if tag_list_cache.blank?
    tag_list_cache
  end

  def tag_list_plus_alias
    return '' if new_record?

    update_columns tag_list_plus_alias_cache: tags_plus_aliased.map(&:name).flatten.sort.join(', ') if tag_list_plus_alias_cache.blank?
    tag_list_plus_alias_cache
  end

  # wtf
  def nuke_tag_caches!
    assign_attributes tag_list_cache: nil, tag_list_plus_alias_cache: nil, file_name_cache: nil
    tag_list
    tag_list_plus_alias
    file_name
    update_columns updated_at: Time.zone.now
  end

  def uploader_is?(user, ip)
    is_uploader = false
    if user
      is_uploader = (user.id == try(:user_id))
    # Don't consider anons with same IP the uploader unless no user
    elsif !user_id
      is_uploader = (ip == self.ip)
    end
    is_uploader
  end

  def visible_to?(user)
    !hidden_from_users || can_see_when_hidden?(user)
  end

  def can_see_when_hidden?(user)
    user && (user.can?(:undelete, Image) || can_see_and_merged?(user) && !merged_into_deleted?)
  end

  def uploader
    if anonymous || user.nil?
      I18n.t('booru.anonymous_user')
    else
      user.name
    end
  end

  def detect_duplicates(dist = 0.20, aspect_dist = 0.05)
    ImageQuery.duplicates(intensity, dist)
              .where('image_aspect_ratio BETWEEN ? AND ?', image_aspect_ratio - aspect_dist, image_aspect_ratio + aspect_dist)
              .where.not(id: id)
              .where.not(duplication_checked: true)
  end

  def title
    "Image ##{id}"
  end

  def link_to_route
    "/#{id}"
  end

  def artist_list
    @artist_list ||= tags.joins(:users).includes(:users).where(namespace: %w[artist photographer]).limit(2).flat_map(&:users).uniq
  end

  # Computes the Wilson confidence upper bound of approval for this image, based
  # on the number of votes it has, with 99.5% significance.
  #
  # See https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval
  # for mathematical detail.
  #
  # @return [Float]
  def wilson_score
    # Population size
    n = upvotes_count.to_f + downvotes_count
    return 0 if n <= 0

    # Success proportion
    p_hat = upvotes_count / n

    # z and z^2-values for CI upper 99.5%
    z  = 2.57583
    z2 = 6.634900189

    (p_hat + z2 / (2 * n) - z * Math.sqrt((p_hat * (1 - p_hat) + z2 / (4 * n)) / n)) / (1 + z2 / n)
  end

  private

  # For +#can_see_when_hidden?+
  def can_see_and_merged?(user)
    duplicate_id && user.can?(:reject, DuplicateReport)
  end

  def merged_into_deleted?
    Image.find(id: duplicate_id).hidden_from_users rescue false
  end
end
