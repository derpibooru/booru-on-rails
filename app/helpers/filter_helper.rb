# frozen_string_literal: true

require 'search_evaluator'

module FilterHelper
  def image_filter_data(image)
    {
      id:                     image.id,
      'namespaced_tags.name': image.tag_list_plus_alias.split(', '),
      score:                  image.score,
      faves:                  image.faves_count,
      upvotes:                image.upvotes_count,
      downvotes:              image.downvotes_count,
      comment_count:          image.comments_count,
      created_at:             image.created_at,
      first_seen_at:          image.first_seen_at,
      source_url:             image.source_url,
      width:                  image.image_width,
      height:                 image.image_height,
      aspect_ratio:           image.image_aspect_ratio,
      sha512_hash:            image.image_sha512_hash,
      orig_sha512_hash:       image.image_orig_sha512_hash
    }
  end

  def filter_or_spoiler_hits?(image)
    filter_hits?(image) || spoiler_hits?(image)
  end

  def filter_hits?(image)
    tag_filter_hits?(image) || complex_filter_hits?(image)
  end

  def spoiler_hits?(image)
    tag_spoiler_hits?(image) || complex_spoiler_hits?(image)
  end

  def tag_filter_hits?(image)
    (@current_filter.hidden_tag_ids & image.tag_ids).any?
  end

  def tag_spoiler_hits?(image)
    (@current_filter.spoilered_tag_ids & image.tag_ids).any?
  end

  def complex_filter_hits?(image)
    fd = image_filter_data(image)
    filter_evaluator.hits?(fd)
  end

  def complex_spoiler_hits?(image)
    fd = image_filter_data(image)
    spoiler_evaluator.hits?(fd)
  end

  def filter_evaluator
    @filter_evaluator ||= SearchEvaluator.new(@current_filter.hidden_complex)
  end

  def spoiler_evaluator
    @spoiler_evaluator ||= SearchEvaluator.new(@current_filter.spoilered_complex)
  end
end
