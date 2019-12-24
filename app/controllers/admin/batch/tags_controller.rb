# frozen_string_literal: true

class Admin::Batch::TagsController < ApplicationController
  def update
    authorize! :batch_update, Tag

    tags = params[:tags].split(',').map { |t| Tag.clean_tag_name(t) }

    added_tags   = Tag.where(name: tags.reject { |x| x[0] == '-' })
    removed_tags = Tag.where(name: tags.select { |x| x[0] == '-' }.map { |x| x[1..-1] })

    tag_change = request_attributes
    batch = { succeeded: [], failed: [] }

    Image.where(id: params[:image_ids]).find_each do |image|
      image.tag_input = ((image.tags - removed_tags) + added_tags).map(&:name).join(',')
      if image.save
        tag_changes =
          image.tags_added.map   { |tag| tag_change.merge(added: true, image: image, tag: tag)  } +
          image.tags_removed.map { |tag| tag_change.merge(added: false, image: image, tag: tag) }
        TagChange.create tag_changes
        batch[:succeeded] << image.id
      else
        batch[:failed] << image.id
      end
    end

    BulkIndexUpdateJob.perform_later 'Image', batch[:succeeded]
    BatchUpdateLogger.log(current_user.name, tags.join(', '), batch[:succeeded].size)

    render json: batch
  end
end
