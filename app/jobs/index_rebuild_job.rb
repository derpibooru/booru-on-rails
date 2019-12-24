# frozen_string_literal: true

class IndexRebuildJob < ApplicationJob
  queue_as :rebuilds
  def perform(cls, id)
    obj = cls.constantize.find(id)
    obj.update_index(defer: false) if obj
  end
end
