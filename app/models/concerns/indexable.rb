# frozen_string_literal: true

require 'elasticsearch/model'

module Indexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include "#{name}Index".constantize

    after_commit(on: :create) do
      __elasticsearch__.index_document
    end

    after_commit(on: :destroy) do
      __elasticsearch__.delete_document
    end
  end

  def update_index(defer: true, priority: :high)
    if defer
      if priority == :high
        IndexUpdateJob.perform_later(self.class.to_s, id)
      elsif priority == :rebuild
        IndexRebuildJob.perform_later(self.class.to_s, id)
      else
        raise ArgumentError, 'No such priority known'
      end
    else
      __elasticsearch__.index_document
    end
  end
end
