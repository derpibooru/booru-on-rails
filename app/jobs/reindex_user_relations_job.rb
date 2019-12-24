# frozen_string_literal: true

# Defers the indexing of searchable objects related to a given user.
# This is essentially a deferred call to #index_related_objects with
# some logging attached.
class ReindexUserRelationsJob < ApplicationJob
  queue_as :rebuilds

  def perform(user_id)
    user = User.find(user_id)

    Image.import(query: -> { where(id: Image::Vote.where(user: user).select(:image_id)) })
    Image.import(query: -> { where(id: Image::Fave.where(user: user).select(:image_id)) })
    Image.import(query: -> { where(id: Image::Hide.where(user: user).select(:image_id)) })
    Image.import(query: -> { where(user: user) })

    [Report, Comment, Post].each do |model|
      BulkIndexUpdateJob.perform_later(model.to_s, model.where(user: user).pluck(:id))
    end
  end
end
