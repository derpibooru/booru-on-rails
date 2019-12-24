# frozen_string_literal: true

module GalleryIndex
  def self.included(base)
    base.document_type 'gallery'

    base.settings index: { number_of_shards: 5 } do
      mappings dynamic: false, _all: { enabled: false } do
        indexes :id,            type: 'integer' # used as keyword
        indexes :image_count,   type: 'integer'
        indexes :watcher_count, type: 'integer'
        indexes :updated_at,    type: 'date'
        indexes :created_at,    type: 'date'
        indexes :first_seen_at, type: 'date' # mistakenly added
        indexes :title,         type: 'keyword'
        indexes :creator,       type: 'keyword' # missing creator_id
        indexes :image_ids,     type: 'keyword'
        indexes :watcher_ids,   type: 'keyword'
        indexes :description,   type: 'text', analyzer: 'snowball'
      end
    end

    base.__elasticsearch__.extend ElasticsearchMethods
    base.extend ClassMethods
  end

  module ElasticsearchMethods
    def import(options = {}, &block)
      # Allow a query
      q = options[:query] || -> { self }
      super(options.merge(query: -> { includes(:creator, :gallery_interactions, :subscribers).instance_exec(&q) }), &block)
    end
  end

  module ClassMethods
    def allowed_search_fields(*)
      [:title, :description, :creator, :watcher_id, :hide_empty, :include_image]
    end

    def allowed_sort_fields
      [:created_at, :first_seen_at, :updated_at, :title, :image_count, :watcher_count]
    end
  end

  def as_json(options = {})
    d = {
      id:              id,
      title:           title,
      description:     description,
      spoiler_warning: spoiler_warning,
      updated_at:      updated_at,
      created_at:      created_at,
      creator_id:      creator_id,
      watcher_count:   subscribers.count,
      image_count:     image_count
    }
    d[:image_ids] = gallery_interactions.order(position: :desc).pluck(:image_id) if options[:include_images]
    d
  end

  def as_indexed_json(*)
    {
      id:            id,
      image_count:   image_count,
      watcher_count: subscribers.count,
      updated_at:    updated_at,
      created_at:    created_at,
      title:         title.downcase,
      creator:       creator.name.downcase,
      image_ids:     gallery_interactions.map(&:image_id),
      watcher_ids:   subscribers.map(&:id),
      description:   description
    }
  end
end
