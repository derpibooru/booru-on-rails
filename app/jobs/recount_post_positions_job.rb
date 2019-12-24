# frozen_string_literal: true

class RecountPostPositionsJob < ApplicationJob
  queue_as :rebuilds

  def self.perform(topic_id)
    Topic.find(topic_id).recount_post_positions!(defer_index: true, index_prio: :rebuild)
  rescue StandardError => ex
    Rails.logger.error("Got exception while recounting post positions on Topic #{topic_id}: #{ex}\n#{ex.inspect}\n#{ex.backtrace}")
  end
end
