# frozen_string_literal: true

module FilterIndex
  def self.included(base)
    base.document_type 'filter'

    # TODO: why do we have this index at all?
    base.settings index: { number_of_shards: 5 } do
      mappings dynamic: false, _all: { enabled: false } do
        indexes :id,                type: 'integer'
        indexes :user_count,        type: 'integer'
        indexes :user_id,           type: 'keyword'
        indexes :name,              type: 'keyword'
        indexes :hidden_tag_ids,    type: 'keyword'
        indexes :spoilered_tag_ids, type: 'keyword'
        indexes :hidden_tags,       type: 'keyword'
        indexes :spoilered_tags,    type: 'keyword'
        indexes :system,            type: 'boolean'
        indexes :public,            type: 'boolean'
        indexes :description,       type: 'text', analyzer: 'snowball'
      end
    end

    base.extend ClassMethods
  end

  module ClassMethods
    def default_sort(_options = {})
      [user_count: :desc]
    end

    def allowed_search_fields(access_options = {})
      fields = [:name, :description, :spoilered_tags, :hidden_tags, :user_count, :system]
      fields += [:user_id, :id, :public] if access_options[:is_mod]
      fields
    end
  end

  def as_json(*)
    {
      id:                id,
      name:              name,
      description:       description,
      hidden_tag_ids:    hidden_tag_ids,
      spoilered_tag_ids: spoilered_tag_ids,
      spoilered_tags:    spoilered_tags.map(&:name),
      hidden_tags:       hidden_tags.map(&:name),
      hidden_complex:    hidden_complex_str,
      spoilered_complex: spoilered_complex_str,
      public:            public,
      system:            system,
      user_count:        user_count,
      user_id:           (user_id || nil)
    }
  end

  def as_indexed_json(*)
    as_json
  end
end
