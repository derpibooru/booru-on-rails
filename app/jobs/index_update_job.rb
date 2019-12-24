# frozen_string_literal: true

class IndexUpdateJob < ApplicationJob
  queue_as :high
  def perform(cls, id)
    obj = cls.constantize.find(id)
    obj.update_index(defer: false) if obj
  rescue StandardError => ex
    Rails.logger.error ex.message
  end
end
