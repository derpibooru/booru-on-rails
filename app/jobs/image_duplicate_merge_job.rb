# frozen_string_literal: true

class ImageDuplicateMergeJob < ApplicationJob
  queue_as :high

  def perform(source_id, target_id, user_id)
    return if source_id == target_id

    source = Image.find source_id
    target = Image.find target_id
    user = User.find_by(id: user_id)

    # Move votes/faves
    Image::VoteMigration.new(source: source, target: target).save

    # Move tags
    target.add_tags source.tags - target.tags

    # Move first_seen_at if necessary
    target.first_seen_at = source.first_seen_at if target.first_seen_at > source.first_seen_at

    # Move featured_on if necessary
    if !source.featured_on.nil?
      target.featured_on = source.featured_on
      source.featured_on = nil
    end

    # Notifications and watchers
    Image::Subscription.insert_all(
      source.subscriptions.select(target.id, :user_id),
      columns: [:image_id, :user_id]
    )
    source.clear_notifications!

    # Galleries
    source.gallery_interactions.update_all image_id: target_id
    target.gallery_interactions.non_uniq(&:gallery_id).each do |interactions|
      remaining, *deleted = *interactions
      deleted.each(&:delete)

      gallery = remaining.gallery
      gallery.update_column :image_count, gallery.gallery_interactions.count
    end

    # Comments
    # TODO: Rethink this - there are images with tens of thousands of comments
    source_comment_ids = source.comments.pluck(:id)
    source.comments.update_all image_id: target_id
    source.update_columns(comments_count: source.comments.count)
    target.update_columns(comments_count: target.comments.count)
    BulkIndexUpdateJob.perform_later 'Comment', source_comment_ids

    # Finish up
    source.duplication_checked = true
    source.duplicate_id = target_id
    ImageHider.new(source, user: user, reason: "System deduplication: #{target_id}").save
    target.save!
    target.update_index(defer: false)
  end
end
