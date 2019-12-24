# frozen_string_literal: true

class ImageUnhider < Unhider
  def after_save
    # Do this before setting hidden_image_key to nil
    @component.image.move_hidden_versions!
    @component.update_columns(duplicate_id: nil, hidden_image_key: nil)

    # Re-add to tag counters
    @component.tags.update_all('images_count = images_count + 1')
    BulkIndexUpdateJob.perform_later 'Tag', @component.tag_ids

    @component.update_index
  end
end
