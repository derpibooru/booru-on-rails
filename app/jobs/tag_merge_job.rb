# frozen_string_literal: true

class TagMergeJob < ApplicationJob
  queue_as :low

  # FIXME: normalize this godawful mess

  def perform(tag_id, target_tag_id, create_alias)
    @tag        = Tag.find(tag_id)
    @target_tag = Tag.find(target_tag_id)

    move_images
    move_relations

    if create_alias
      @tag.update_columns(images_count: 0, aliased_tag_id: @target_tag.id, updated_at: Time.zone.now)
      @tag.update_index
    else
      TagChange.where(tag_id: @tag.id).update_all(tag_id: @target_tag.id)
      @tag.delete
    end

    ReindexTagJob.perform_now(@target_tag.id)
  end

  def move_images
    Image::Tagging.insert_all(
      @tag.images.select(:id, @target_tag.id),
      columns: [:image_id, :tag_id]
    )
    Image::Tagging.where(tag: @tag).delete_all
  end

  def move_relations
    target = @target_tag
    @target_tag.implied_tag_ids = (@target_tag.implied_tag_ids + @tag.implied_tag_ids).compact.uniq

    filters_hidden    = Filter.where('hidden_tag_ids @> ARRAY[?]',    @tag.id)
    filters_spoilered = Filter.where('spoilered_tag_ids @> ARRAY[?]', @tag.id)
    users_watching    = User.where('watched_tag_ids @> ARRAY[?]',     @tag.id)

    PostgresSet.replace(filters_hidden,    :hidden_tag_ids,    @tag.id, @target_tag.id)
    PostgresSet.replace(filters_spoilered, :spoilered_tag_ids, @tag.id, @target_tag.id)
    PostgresSet.replace(users_watching,    :watched_tag_ids,   @tag.id, @target_tag.id)

    UserLink.where(tag_id: @tag.id).update_all(tag_id: @target_tag.id)
    DnpEntry.where(tag_id: @tag.id).update_all(tag_id: @target_tag.id)
    Comment.import(query: -> { where(image_id: target.images.select(:id)) })
  end
end
