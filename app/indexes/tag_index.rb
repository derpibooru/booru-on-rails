# frozen_string_literal: true

module TagIndex
  ANALYZER = {
    analyzer: {
      tag_snowball: {
        tokenizer: :letter,
        filter:    [:asciifolding, :snowball]
      }
    }
  }.freeze

  def self.included(base)
    base.document_type 'tag'

    base.settings index: { number_of_shards: 5, analysis: ANALYZER } do
      mappings dynamic: false, _all: { enabled: false } do
        indexes :id,                type: 'integer'
        indexes :images,            type: 'integer'
        indexes :slug,              type: 'keyword'
        indexes :name,              type: 'keyword'
        indexes :name_in_namespace, type: 'keyword'
        indexes :namespace,         type: 'keyword'
        indexes :aliased_tag,       type: 'keyword'
        indexes :aliases,           type: 'keyword'
        indexes :implied_tags,      type: 'keyword'
        indexes :implied_tag_ids,   type: 'keyword'
        indexes :implied_by_tags,   type: 'keyword'
        indexes :category,          type: 'keyword'
        indexes :aliased,           type: 'boolean'
        indexes :analyzed_name,     type: 'text' do
          indexes :nlp,   type: 'text',   analyzer: 'tag_snowball'
          indexes :ngram, type: 'keyword'
        end
        indexes :description,       type: 'text', analyzer: 'snowball'
        indexes :short_description, type: 'text', analyzer: 'snowball'
      end
    end

    base.__elasticsearch__.extend ElasticsearchMethods
    base.extend ClassMethods
  end

  module ElasticsearchMethods
    def import(options = {}, &block)
      # Allow a query
      q = options[:query] || -> { self }
      super(options.merge(query: -> { includes(:aliased_tag, :aliases, :implied_tags, :implied_by_tags).instance_exec(&q) }), &block)
    end
  end

  module ClassMethods
    def default_sort(*)
      [images: :desc]
    end

    def allowed_search_fields(*)
      [
        :id, :images, :slug, :name, :name_in_namespace, :namespace, :implies,
        :alias_of, :implied_by, :aliases, :category, :aliased, :analyzed_name,
        :description, :short_description
      ]
    end

    def default_field
      :analyzed_name
    end

    def field_aliases
      {
        implies:    :implied_tags,
        implied_by: :implied_by_tags,
        alias_of:   :aliased_tag
      }
    end
  end

  def as_json(*)
    {
      id:                id,
      name:              name,
      slug:              slug,
      description:       description,
      short_description: short_description,
      images:            images_count,
      spoiler_image_uri: spoiler_image_uri,
      aliased_to:        aliased_tag_name,
      aliased_to_id:     aliased_tag_id,
      namespace:         namespace,
      name_in_namespace: name_in_namespace,
      implied_tags:      implied_tags.map(&:name),
      implied_tag_ids:   implied_tag_ids,
      category:          category
    }
  end

  def as_indexed_json(*)
    {
      id:                id,
      images:            images_count,
      slug:              slug,
      name:              name,
      name_in_namespace: name_in_namespace,
      namespace:         namespace,
      analyzed_name:     name,
      implied_tags:      implied_tags.map(&:name),
      implied_tag_ids:   implied_tag_ids,
      implied_by_tags:   implied_by_tags.map(&:name),
      aliased_tag:       aliased_tag&.name,
      aliases:           aliases.map(&:name),
      category:          category,
      aliased:           aliased_tag_id.present?,
      description:       description,
      short_description: short_description
    }
  end
end
