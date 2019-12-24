# frozen_string_literal: true

class ReindexTagJob < ApplicationJob
  queue_as :high

  def perform(tag_id)
    tag = Tag.find(tag_id)

    TagLogger.log(tag.name, 'Reindexing tag', "reindexing #{tag.images.count} images")

    tag.images.update_all(tag_list_cache: nil, tag_list_plus_alias_cache: nil, file_name_cache: nil, updated_at: Time.zone.now)
    Image.import(query: -> { where(id: tag.images.select(:id)) })
    CountImagesJob.perform_now(tag.id)
  end
end
