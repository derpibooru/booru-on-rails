# frozen_string_literal: true

module PostIndex
  extend ActiveSupport::Concern

  included do
    document_type 'post'

    settings index: { number_of_shards: 5 } do
      mappings dynamic: false, _all: { enabled: false } do
        indexes :id, type: 'integer'
        indexes :body, analyzer: 'snowball', type: 'text'
        indexes :ip, type: 'ip'
        indexes :user_agent, type: 'keyword'
        indexes :referrer, type: 'keyword'
        indexes :fingerprint, type: 'keyword'
        indexes :subject, analyzer: 'snowball', type: 'text'
        indexes :author, type: 'keyword'
        indexes :topic_position, type: 'integer'
        indexes :forum_id, type: 'keyword'
        indexes :topic_id, type: 'keyword'
        indexes :user_id, type: 'keyword'
        indexes :anonymous, type: 'boolean'
        indexes :updated_at, type: 'date'
        indexes :created_at, type: 'date'
        indexes :deleted, type: 'boolean'
        indexes :access_level, type: 'keyword'
        indexes :destroyed_content, type: 'boolean'
      end
    end
  end

  class_methods do
    def allowed_search_fields(access_options = {})
      fields = [:author, :subject, :body, :topic_position]
      fields += [:ip, :fingerprint] if access_options[:is_mod]
      fields
    end

    def fancy_search(options, &block)
      super(options) do |s|
        yield s if block

        if options[:include_deleted] == :only
          s.add_filter(term: { deleted: 'true' })
        elsif !(options[:include_deleted])
          s.add_filter(term: { deleted: false })
        end

        s.add_filter(term: { destroyed_content: false }) if !(options[:include_destroyed])
      end
    end

    def default_sort(_options = {})
      [updated_at: :desc]
    end
  end

  def as_json(options = {})
    d = {
      id:       id,
      topic_id: topic_id,
      body:     options[:show_deleted] || !hidden_from_users ? body : '',
      author:   author
    }
    d[:subject] = topic.title if first?
    d
  end

  def as_indexed_json(*)
    d = as_json(show_deleted: true)
    d[:ip] = ip&.to_s
    d[:user_agent] = user_agent
    d[:referrer] = referrer
    d[:fingerprint] = fingerprint
    d[:subject] = (d[:subject] || topic.title)
    d[:topic_position] = topic_position
    d[:forum_id] = topic.forum_id
    d[:author] = user.try(:name).to_s.downcase
    d[:user_id] = user_id
    d[:anonymous] = anonymous
    d[:created_at] = created_at.iso8601(4) rescue nil
    d[:updated_at] = updated_at.iso8601(4) rescue nil
    d[:deleted] = hidden_from_users
    d[:access_level] = topic.forum.access_level
    d[:destroyed_content] = destroyed_content
    d
  end
end
