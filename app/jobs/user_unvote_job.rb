# frozen_string_literal: true

class UserUnvoteJob < ApplicationJob
  queue_as :low
  def perform(id, upvotes_and_faves_too = false)
    user = User.find(id)

    Image::Vote.where(user: user, up: false).find_each do |v|
      v.destroy
      IndexRebuildJob.perform_later('Image', v.image_id)
    rescue StandardError
      nil
    end

    if upvotes_and_faves_too
      Image::Vote.where(user: user).find_each do |v|
        v.destroy
        IndexRebuildJob.perform_later('Image', v.image_id)
      rescue StandardError
        nil
      end

      Image::Fave.where(user: user).find_each do |f|
        f.destroy
        IndexRebuildJob.perform_later('Image', f.image_id)
      rescue StandardError
        nil
      end
    end
  end
end
