# frozen_string_literal: true

module ReportIndex
  def self.included(base)
    base.document_type 'report'

    base.settings index: { number_of_shards: 5 } do
      mappings dynamic: false, _all: { enabled: false } do
        indexes :id,              type: 'integer' # used as keyword
        indexes :image_id,        type: 'integer' # used as keyword
        indexes :created_at,      type: 'date'
        indexes :ip,              type: 'ip'
        indexes :state,           type: 'keyword'
        indexes :user,            type: 'keyword'
        indexes :user_id,         type: 'keyword'
        indexes :admin,           type: 'keyword'
        indexes :admin_id,        type: 'keyword'
        indexes :reportable_type, type: 'keyword'
        indexes :reportable_id,   type: 'keyword'
        indexes :fingerprint,     type: 'keyword'
        indexes :open,            type: 'boolean'
        indexes :reason,          type: 'text', analyzer: 'snowball'
      end
    end

    base.__elasticsearch__.extend ElasticsearchMethods
    base.extend ClassMethods
  end

  module ElasticsearchMethods
    def import(options = {}, &block)
      # Allow a query
      q = options[:query] || -> { self }
      super(options.merge(query: -> { includes(:user, :admin, :reportable).instance_exec(&q) }), &block)
    end
  end

  module ClassMethods
    def default_sort(*)
      [created_at: :desc]
    end

    def allowed_search_fields(*)
      [:id, :created_at, :reason, :state, :user, :user_id, :admin, :admin_id,
       :ip, :fingerprint, :reportable_type, :reportable_id, :image_id]
    end

    def default_field
      :reason
    end
  end

  def as_json(*)
    d = {
      id:              id,
      image_id:        (reportable_id if reportable_type == 'Image'),
      created_at:      created_at,
      ip:              ip.to_s,
      state:           state,
      user:            user&.name&.downcase,
      user_id:         user_id,
      admin:           admin&.name&.downcase,
      admin_id:        admin_id,
      reportable_type: reportable_type.downcase,
      reportable_id:   reportable_id,
      fingerprint:     fingerprint,
      open:            open,
      reason:          reason
    }

    d[:image_id] = reportable_id       if reportable_type == 'Image'
    d[:image_id] = reportable.image_id if reportable_type == 'Comment'

    d
  end

  def as_indexed_json(*)
    as_json
  end
end
