# frozen_string_literal: true

class ProcessVideoJob < ApplicationJob
  queue_as :video_processing

  # Only enqueue this job after the transaction has finished. It may be tempting to use callbacks
  # provided by CarrierWave (after :store) to do so, but they are executed in after_save context,
  # meaning that processing can be performed for the incorrect model state.
  def perform(image_id)
    image = Image.find(image_id)
    image.image.move_hidden_versions!
    image.image.process_after_creation!
    DuplicateReport.generate_reports(image)

    ImageCloudflarePurgeJob.perform_later image_id
  end
end
