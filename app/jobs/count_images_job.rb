# frozen_string_literal: true

class CountImagesJob < ApplicationJob
  queue_as :rebuilds
  def perform(id)
    tag = Tag.find(id)
    tag.update_images_count!
    tag.update_index(defer: false)
  end
end
