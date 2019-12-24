# frozen_string_literal: true

class Tag < ApplicationRecord
  include FancySearchable
  include Indexable
  include Sluggable

  resourcify

  file :image,
    store_dir:  Booru::CONFIG.settings[:tags_file_path],
    url_prefix: Booru::CONFIG.settings[:tags_url_prefix]

  file_validator :image,
    validator: :image_validator,
    mime:      %w[image/gif image/jpeg image/png image/svg+xml]

  set_slugged_field :name

  belongs_to :aliased_tag, class_name: 'Tag', validate: false, inverse_of: :aliases, optional: true
  has_many :aliases, foreign_key: :aliased_tag_id, inverse_of: :aliased_tag, class_name: 'Tag', validate: false
  has_many :dnp_entries
  has_many :user_links
  has_many :users, through: :user_links
  has_many :taggings, class_name: 'Image::Tagging'
  has_many :images, through: :taggings
  has_and_belongs_to_many :implied_tags, join_table: 'tags_implied_tags', association_foreign_key: 'implied_tag_id', class_name: 'Tag'
  has_and_belongs_to_many :implied_by_tags, join_table: 'tags_implied_tags', foreign_key: 'implied_tag_id', class_name: 'Tag'

  attr_accessor :target_tag_name

  validates :name, presence: true
  validates :name, length: { maximum: 75 }
  validates :name, format: { with: /\A[^,]+\z/, on: :create, message: 'cannot contain commas' }
  validates :category, inclusion: { allow_nil: true, in: Booru::CONFIG.tag[:categories] }
  validates :category, inclusion: { in: %w[rating], if: :rating_tag?, message: 'of a rating tag cannot be changed.' }
  validates_with TagDestructionValidator, on: :destroy
  validates_with TagAliasValidator, if: :target_tag_name_updated?

  before_validation :set_aliased_tag, if: :target_tag_name_updated?
  before_validation :normalize_name!, :set_namespaced_names!, :set_slug
  before_validation :set_category!, on: :create
  before_validation { self.category = category.presence }

  def self.categories
    Booru::CONFIG.tag[:categories]
  end

  def self.category_labels
    Booru::CONFIG.tag[:category_labels]
  end

  def self.category_namespaces
    Booru::CONFIG.tag[:category_namespaces]
  end

  def self.rating_tags
    where(name: Booru::CONFIG.tag[:rating_tags])
  end

  def self.without_rating_tags
    where.not(name: Booru::CONFIG.tag[:rating_tags])
  end

  def self.display_order
    order(Arel.sql("category='spoiler' ASC, category='content-official' ASC, category='content-fanmade' ASC, category='species' ASC, category='oc' ASC, category='character' ASC, category='origin' ASC, category='rating' ASC, name ASC"))
  end

  def implied_tag_list
    implied_tags.map(&:name).join(', ')
  end

  def implied_tag_list=(val)
    self.implied_tags = Tag.where(name: Tag.parse_tag_list(val)).to_a
  end

  def rating_tag?
    Booru::CONFIG.tag[:rating_tags].include?(name)
  end

  def destroy
    return false unless valid?(:destroy)

    TagDestructionJob.perform_later(id)
  end

  def normalize_name!
    self.name = Tag.clean_tag_name(name)
  end

  def set_namespaced_names!(force = false)
    return name_in_namespace if name_in_namespace && !force

    self.namespace = name.split(':').size > 1 ? name.split(':')[0] : nil
    self.name_in_namespace = name.split(':').size > 1 ? name.split(':')[1..-1].join(':') : name
  end

  def set_category!
    self.category = Tag.category_namespaces[namespace] || category
    self.category = 'rating' if rating_tag?
  end

  def set_aliased_tag
    self.aliased_tag = Tag.find_tag_by_name(target_tag_name)
  end

  def aliased_tag_name
    aliased_tag.try(:name)
  end

  def target_tag_name_updated?
    target_tag_name && (target_tag_name.presence != aliased_tag_name || target_tag_name == name)
  end

  # Return verified links
  def associated_links(public_only = true)
    if public_only
      UserLink.where(tag_id: id).verified.order(hostname: :desc).where(public: true)
    else
      UserLink.where(tag_id: id).verified.order(hostname: :desc)
    end
  end

  # Return verified user associations
  def associated_users(public_only = true)
    associated_links(public_only).includes(:user).map(&:user).uniq
  end

  def spoiler_image_uri
    uploaded_image.url if image.present?
  end

  def to_param
    slug
  end

  def update_images_count!
    update_attribute(:images_count, images.where(hidden_from_users: false).count)
  end

  def self.merge_ratings(tags)
    ratings_in  = (tags & Booru::CONFIG.ratings[:ratings].keys).uniq
    ratings_out = ratings_in.dup

    Booru::CONFIG.ratings[:ratings].values.each do |rating|
      ratings_out -= rating[:replaces] if ratings_out.include?(rating[:name])
    end

    tags - ratings_in + ratings_out
  end

  def self.parse_tag_list(tag_string)
    tag_string.split(',').reject(&:blank?).map { |name| Tag.clean_tag_name(name) }
  end

  def self.find_tag_by_name(tag_name)
    tag = Tag.find_by(name: Tag.clean_tag_name(tag_name))
    tag&.aliased_tag || tag
  end

  def self.make_tags_from_names(tag_names, create_if_missing: true)
    tag_names = tag_names.map { |tag_name| Tag.clean_tag_name(tag_name) }
    existing_tags = Tag.includes(:implied_tags, :aliased_tag).where(name: tag_names).distinct
    new_tags = if create_if_missing
      # Grab all the names Rails didn't find tags for to create new tags with
      new_tag_names = (tag_names - existing_tags.map(&:name))
      new_tag_names.map { |new_tag_name| Tag.create!(name: new_tag_name) }
    end
    # Deal with aliases on the existing tags
    existing_tags = existing_tags.map { |tag| tag.aliased_tag || tag }
    existing_tags + new_tags
  end

  def self.clean_tag_name(name)
    name = name.downcase
               .squish
               .gsub(/[\u00b4\u2018\u2019\u201a\u201b\u2032]/, "'") # fancy unicode quotes
               .gsub(/[\u00b4\u201c\u201d\u201e\u201f\u2033]/, '"')

    # Remove extra spaces after the colon in a namespace ('artist:', 'oc:', etc.)
    if name.include?(': ') || name.include?(' :')
      parts = name.split(':', 2).map(&:strip)
      name = parts.join(':') if Booru::CONFIG.tag[:namespaces].include?(parts.first)
    end
    name = name.delete('_') unless name.start_with?('artist:')
    name
  end
end
