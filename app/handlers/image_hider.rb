# frozen_string_literal: true

class ImageHider < ReportableHider
  def before_save
    @component.tags.update_all('images_count = images_count - 1')
    BulkIndexUpdateJob.perform_later 'Tag', @component.tag_ids
    @component.hidden_image_key ||= SecureRandom.hex(6)
  end

  def after_save
    super
    @component.image.move_hidden_versions!
    @component.clear_notifications!

    if @component.user
      @component.subscriptions.delete_all
      @component.subscriptions.create!(user: @component.user)
      Notification.async_notify @component, "deleted (for '#{@component.deletion_reason}')"
    end

    DuplicateReport.where('(image_id = ? OR duplicate_of_image_id = ?) AND state = ?', @component.id, @component.id, 'open').update_all(state: 'rejected')
    @component.update_index
    ImageCloudflarePurgeJob.perform_later(@component.id)
  end
end
