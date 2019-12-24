# frozen_string_literal: true

class Filter < ApplicationRecord
  include ActiveRecord::Sanitization::ClassMethods
  include FancySearchable
  include Reportable
  include Indexable
  include QueryAssociable

  # Relations
  belongs_to :user, inverse_of: :filters, optional: true
  has_many   :current_users, class_name: 'User', inverse_of: :current_filter
  has_array_field :hidden_tags, Tag
  has_array_field :spoilered_tags, Tag

  has_tag_proxy on: :spoilered_tag_ids, name: :spoilered_tag_list
  has_tag_proxy on: :hidden_tag_ids, name: :hidden_tag_list

  # Validations
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :hidden_complex_str, :spoilered_complex_str, format: { without: /my:downvotes/i, message: 'cannot contain my:downvotes' }
  validates_with ImageQueryValidator, fields: [:hidden_complex_str, :spoilered_complex_str]

  before_destroy do |filter|
    # Unsubscribe users from this nonexistent filter
    User.where(current_filter_id: filter.id).find_each do |user|
      user.set_filter!(Filter.default_filter)
    end
  end

  # Callback from User#set_filter! when a user switches away from this filter
  def on_lost_user
    Filter.decrement_counter(:user_count, id)
    update_index
  end

  # Callback from User#set_filter! when a user switches to this filter
  def on_gained_user
    Filter.increment_counter(:user_count, id)
    update_index
  end

  # Return an array of the spoilered tag IDs for a given image
  def image_spoilered_tag_ids(image)
    image.tag_ids & spoilered_tag_ids
  end

  # Returns an array of the hidden tag IDs for a given image
  def image_hidden_tag_ids(image)
    image.tag_ids & hidden_tag_ids
  end

  # Returns a spoiler tag for a given image, which will be the first tag with an image
  def image_spoiler_tag(image)
    select_tag_with_image(image_spoilered_tag_ids(image))
  end

  # Returns a hidden tag for a given image, which will be the first tag with an image
  def image_hidden_tag(image)
    select_tag_with_image(image_hidden_tag_ids(image))
  end

  def customizable_copy(user)
    filter = Filter.new
    filter.name = "#{user.name}'s #{name}"
    filter.description = description
    filter.spoilered_tag_ids = spoilered_tag_ids
    filter.hidden_tag_ids = hidden_tag_ids
    filter.hidden_complex_str = hidden_complex_str
    filter.spoilered_complex_str = spoilered_complex_str
    filter.user = user
    filter
  end

  def normalized_hidden_complex_str
    Filter.normalize_user_query_program(hidden_complex_str)
  end

  def normalized_spoilered_complex_str
    Filter.normalize_user_query_program(spoilered_complex_str)
  end

  # Return the default filter
  def self.default_filter
    @default_filter ||= Filter.find_or_initialize_by(name: 'Default', system: true)
  end

  # Return the filter for the current user
  def self.get_filter(user)
    return Filter.default_filter unless user
    return user.current_filter if user.current_filter

    user.set_default_filter! if user && !user.current_filter
  end

  def self.for_menu(user)
    sanitized = sanitize_sql_array([
      "select id, name, 'f'::bool as recent from filters where filters.user_id = ? union select id, name, 't'::bool as recent from filters where filters.id in (?) order by name asc",
      user.id,
      user.recent_filter_ids
    ])
    recent_filters, user_filters = Filter.find_by_sql(sanitized).partition(&:recent)

    options = [['Your Filters', user_filters.map { |f| [f.name, f.id.to_s] }]]
    options.push(['Recent Filters', recent_filters.map { |f| [f.name, f.id.to_s] }]) if recent_filters.any?
    options
  end

  def self.for(user, fallback_filter_id = nil)
    if user
      Filter.get_filter(user)
    elsif fallback_filter_id
      filter = Filter.find(fallback_filter_id) rescue nil
      return filter if filter

      Filter.default_filter
    else
      Filter.default_filter
    end
  end

  def hidden_complex(options = {})
    Filter.parse_user_query_program(hidden_complex_str, Image, options)
  end

  def spoilered_complex(options = {})
    Filter.parse_user_query_program(spoilered_complex_str, Image, options)
  end

  private

  # For a given set of tag IDs, select the first one with a custom image or the first one if that fails
  def select_tag_with_image(tag_ids)
    return nil if tag_ids.blank?

    @tag_ids_cache ||= {}
    @tag_ids_cache[tag_ids] ||= (Tag.where.not(image: nil).find_by(id: tag_ids) || Tag.find_by(id: tag_ids))
  end
end
