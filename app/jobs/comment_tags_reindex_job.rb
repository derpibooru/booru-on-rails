# frozen_string_literal: true

class CommentTagsReindexJob < ApplicationJob
  queue_as :rebuilds

  def perform(image_id)
    Comment.import(query: -> { where(image_id: image_id) })
  end
end
