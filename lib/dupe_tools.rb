# frozen_string_literal: true

module DupeTools
  FORMATS_ORDER = %w[video/webm image/svg+xml image/png image/gif image/jpeg other].freeze

  def forward_merge?
    duplicate_of_image.id > image.id
  end

  def higher_res?
    duplicate_of_image.image_width > image.image_width || duplicate_of_image.image_height > image.image_height
  end

  def same_res?
    duplicate_of_image.image_width == image.image_width && duplicate_of_image.image_height == image.image_height
  end

  def same_format?
    duplicate_of_image.image_mime_type == image.image_mime_type
  end

  def better_format?
    source_index = FORMATS_ORDER.index(image.image_mime_type) || FORMATS_ORDER.length - 1
    target_index = FORMATS_ORDER.index(duplicate_of_image.image_mime_type) || FORMATS_ORDER.length - 1

    target_index < source_index
  end

  def same_aspect_ratio?
    (duplicate_of_image.image_aspect_ratio - image.image_aspect_ratio).abs <= 0.009
  end

  def neither_have_source?
    duplicate_of_image.source_url.blank? && image.source_url.blank?
  end

  def same_source?
    duplicate_of_image.source_url.to_s == image.source_url.to_s
  end

  def similar_source?
    host1 = Addressable::URI.parse(image.source_url).host.to_s
    host2 = Addressable::URI.parse(duplicate_of_image.source_url).host.to_s
    host1 == host2 || host1.end_with?('deviantart.com') && host2.end_with?('deviantart.com')
  rescue StandardError
    false # can't parse the URI
  end

  def source_on_target?
    duplicate_of_image.source_url.present? && image.source_url.blank?
  end

  def source_on_source?
    duplicate_of_image.source_url.blank? && image.source_url.present?
  end

  def same_artist_tags?
    source_artist_tags == target_artist_tags
  end

  def more_artist_tags_on_target?
    target_artist_tags.superset? source_artist_tags
  end

  def more_artist_tags_on_source?
    source_artist_tags.superset? target_artist_tags
  end

  def target_artist_tags
    duplicate_of_image.tags.where(namespace: :artist).to_set
  end

  def source_artist_tags
    image.tags.where(namespace: :artist).to_set
  end

  def same_rating_tags?
    target_rating_tags == source_rating_tags
  end

  def target_rating_tags
    duplicate_of_image.tags.rating_tags.to_set
  end

  def source_rating_tags
    image.tags.rating_tags.to_set
  end

  def target_is_edit?
    duplicate_of_image.tags.where(name: 'edit').present?
  end

  def source_is_edit?
    image.tags.where(name: 'edit').present?
  end

  def both_are_edits?
    source_is_edit? && target_is_edit?
  end

  def target_is_alternate_version?
    duplicate_of_image.tags.where(name: 'alternate version').present?
  end

  def source_is_alternate_version?
    image.tags.where(name: 'alternate version').present?
  end

  def both_are_alternate_versions?
    source_is_alternate_version? && target_is_alternate_version?
  end
end
