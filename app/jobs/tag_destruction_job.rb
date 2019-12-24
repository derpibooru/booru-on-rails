# frozen_string_literal: true

class TagDestructionJob < ApplicationJob
  queue_as :low

  def perform(tag_id)
    tag = Tag.find(tag_id)
    tag.with_lock do
      clean_up_associations! tag
      remove_usages! tag

      tag.delete

      ReindexTagJob.perform_later tag.aliased_tag_id if tag.aliased_tag_id
    end
  end

  def clean_up_associations!(tag)
    PostgresSet.pull Filter.where('hidden_tag_ids @> ARRAY[?]', tag.id),    :hidden_tag_ids,    tag.id
    PostgresSet.pull Filter.where('spoilered_tag_ids @> ARRAY[?]', tag.id), :spoilered_tag_ids, tag.id
    PostgresSet.pull User.where('watched_tag_ids @> ARRAY[?]', tag.id),     :watched_tag_ids,   tag.id
  end

  def remove_usages!(tag)
    updated_image_ids = tag.images.pluck(:id)

    Image::Tagging.where(tag: tag).delete_all
    Image.where(id: updated_image_ids).select(:id).find_each(&:nuke_tag_caches!)

    updated_comment_ids = Comment.where(image_id: updated_image_ids).pluck(:id)

    BulkIndexUpdateJob.perform_later 'Image', updated_image_ids
    BulkIndexUpdateJob.perform_later 'Comment', updated_comment_ids
  end
end
