# frozen_string_literal: true

class GalleryReorderJob < ApplicationJob
  queue_as :high

  # Applies new positions to a subset of gallery images (+image_ids+) according to the array order.
  def perform(id, image_ids)
    gallery = Gallery.find(id)

    interactions = gallery.gallery_interactions
                          .where(image_id: image_ids)
                          .order(position: gallery.position_order)

    images_present = interactions.map(&:image_id)
    requested = image_ids.select { |i| images_present.include? i }

    changes = {}

    interactions.each_with_index do |interaction, current_index|
      new_index = requested.index(interaction.image_id)
      changes[interaction.id] = { position: interactions[new_index].position } if new_index != current_index
    end

    gallery.gallery_interactions.update changes.keys, changes.values

    updated_image_ids = interactions.where(id: changes.keys).pluck(:image_id)
    BulkIndexUpdateJob.perform_now 'Image', updated_image_ids
  end
end
