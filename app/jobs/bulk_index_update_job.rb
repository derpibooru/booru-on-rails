# frozen_string_literal: true

class BulkIndexUpdateJob < ApplicationJob
  queue_as :rebuilds

  # Accepts a class name (e.g. 'Image') and an array of object ids.
  def perform(cls, ids)
    return if ids.empty?

    cls.constantize.import(query: -> { where(id: ids) })
  end
end
