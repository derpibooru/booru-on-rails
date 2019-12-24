# frozen_string_literal: true

module CommentIndex
  def self.included(base)
    base.document_type 'comment'

    base.settings index: { number_of_shards: 5 } do
      mappings dynamic: false, _all: { enabled: false } do
        indexes :id,                type: 'integer'
        indexes :posted_at,         type: 'date'
        indexes :ip,                type: 'ip'
        indexes :fingerprint,       type: 'keyword'
        indexes :image_id,          type: 'keyword'
        indexes :user_id,           type: 'keyword'
        indexes :author,            type: 'keyword'
        indexes :image_tag_ids,     type: 'keyword'
        indexes :anonymous,         type: 'keyword' # boolean
        indexes :hidden_from_users, type: 'keyword' # boolean
        indexes :body,              type: 'text', analyzer: 'snowball'
      end
    end

    base.__elasticsearch__.extend ElasticsearchMethods
    base.extend ClassMethods
  end

  module ElasticsearchMethods
    def import(options = {}, &block)
      # Allow a query
      q = options[:query] || -> { self }
      super(options.merge(query: -> { includes(:user, image: :tags).instance_exec(&q) }), &block)
    end
  end

  module ClassMethods
    def default_sort(_options = {})
      [posted_at: :desc]
    end

    def allowed_search_fields(access_options = {})
      fields = [:id, :image_tag_ids, :user_id, :author, :body, :image_id]
      fields += [:ip, :fingerprint] if access_options[:is_mod]
      fields
    end

    def default_field
      :body
    end

    def no_downcase_fields
      [:author]
    end

    def fancy_search(options, &block)
      super(options) do |s|
        yield s if block

        s.add_filter(term: { hidden_from_users: false }) if !options[:include_deleted]
      end
    end
  end

  def as_json(*)
    {
      id:        id,
      body:      (hidden_from_users ? 'Deleted' : body),
      author:    author,
      image_id:  image_id,
      posted_at: created_at,
      deleted:   hidden_from_users
    }
  end

  def as_indexed_json(*)
    {
      id:                id,
      posted_at:         created_at,
      ip:                ip.to_s,
      fingerprint:       fingerprint,
      image_id:          image_id,
      user_id:           user_id,
      author:            author,
      image_tag_ids:     image.tag_ids,
      anonymous:         anonymous,
      hidden_from_users: hidden_from_users,
      body:              body
    }
  end
end
