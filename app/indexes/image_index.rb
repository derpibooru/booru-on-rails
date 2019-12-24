# frozen_string_literal: true

module ImageIndex
  def self.included(base)
    base.document_type 'image'

    base.settings index: { number_of_shards: 5, max_result_window: 10_000_000 } do
      mappings dynamic: false, _all: { enabled: false } do
        indexes :id,                     type: 'integer'
        indexes :upvotes,                type: 'integer'
        indexes :downvotes,              type: 'integer'
        indexes :score,                  type: 'integer'
        indexes :faves,                  type: 'integer'
        indexes :comment_count,          type: 'integer'
        indexes :width,                  type: 'integer'
        indexes :height,                 type: 'integer'
        indexes :tag_count,              type: 'integer'
        indexes :aspect_ratio,           type: 'float'
        indexes :wilson_score,           type: 'float'
        indexes :created_at,             type: 'date'
        indexes :updated_at,             type: 'date'
        indexes :first_seen_at,          type: 'date'
        indexes :ip,                     type: 'ip'

        indexes :tag_ids,                type: 'keyword'
        indexes :namespaced_tags do
          indexes :name,                 type: 'keyword'
          indexes :namespace,            type: 'keyword'
          indexes :name_in_namespace,    type: 'keyword'
        end

        indexes :mime_type,              type: 'keyword'
        indexes :uploader,               type: 'keyword'
        indexes :true_uploader,          type: 'keyword'
        indexes :source_url,             type: 'keyword'
        indexes :file_name,              type: 'keyword'
        indexes :user_id,                type: 'keyword'
        indexes :original_format,        type: 'keyword'
        indexes :fingerprint,            type: 'keyword'
        indexes :uploader_id,            type: 'keyword'
        indexes :true_uploader_id,       type: 'keyword'
        indexes :image,                  type: 'keyword'
        indexes :upvoters,               type: 'keyword'
        indexes :upvoter_ids,            type: 'keyword'
        indexes :downvoters,             type: 'keyword'
        indexes :downvoter_ids,          type: 'keyword'
        indexes :commenters,             type: 'keyword'
        indexes :favourited_by_users,    type: 'keyword'
        indexes :favourited_by_user_ids, type: 'keyword'
        indexes :hidden_by_users,        type: 'keyword'
        indexes :hidden_by_user_ids,     type: 'keyword'
        indexes :deleted_by_user,        type: 'keyword'
        indexes :deleted_by_user_id,     type: 'keyword'
        indexes :orig_sha512_hash,       type: 'keyword'
        indexes :sha512_hash,            type: 'keyword'

        indexes :hidden_from_users,      type: 'keyword' # actually a boolean
        indexes :anonymous,              type: 'boolean'
        indexes :is_optimized,           type: 'boolean'
        indexes :is_rendered,            type: 'boolean'

        indexes :deletion_reason,        type: 'text', analyzer: 'snowball'
        indexes :description,            type: 'text', analyzer: 'snowball'
        indexes :tags,                   type: 'text', analyzer: 'keyword'

        indexes :galleries, type: 'nested' do
          indexes :id,       type: 'integer'
          indexes :position, type: 'integer'
        end
      end
    end

    base.__elasticsearch__.extend ElasticsearchMethods
    base.extend ClassMethods
  end

  module ElasticsearchMethods
    def import(options = {}, &block)
      # Allow a query
      q = options[:query] || -> { self }
      super(options.merge(query: -> { includes(:user, :gallery_interactions, :deleted_by, tags: :aliases, upvotes: :user, downvotes: :user, faves: :user, hides: :user).instance_exec(&q) }), &block)
    end
  end

  module ClassMethods
    def allowed_search_fields(access_options = {})
      fields = [
        :id, :width, :height, :aspect_ratio, :comment_count, :score, :upvotes, :downvotes, :faves,
        :tags, :faved_by, :orig_sha512_hash, :sha512_hash, :score, :uploader, :source_url, :description,
        :created_at, :updated_at, :uploader_id, :first_seen_at, :gallery_id, :faved_by_id, :original_format,
        :tag_count, :wilson_score
      ]
      fields << :my if access_options[:user]

      if access_options[:is_mod]
        fields.concat [
          :ip, :fingerprint, :upvoted_by, :upvoted_by_id, :downvoted_by, :downvoted_by_id, :true_uploader,
          :true_uploader_id, :hidden_by, :hidden_by_id, :deleted_by_user, :deleted_by_user_id, :deletion_reason,
          :deleted
        ]
      end

      fields
    end

    def field_aliases
      {
        faved_by:        :favourited_by_users,
        upvoted_by:      :upvoters,
        downvoted_by:    :downvoters,
        faved_by_id:     :favourited_by_user_ids,
        upvoted_by_id:   :upvoter_ids,
        downvoted_by_id: :downvoter_ids,
        hidden_by:       :hidden_by_users,
        hidden_by_id:    :hidden_by_user_ids,
        deleted:         :hidden_from_users
      }
    end

    def field_transforms(options = {})
      {
        my:         ->(x) do
          case x
          when 'faves'     then { term: { favourited_by_user_ids: options[:user].id.to_s } }
          when 'upvotes'   then { term: { upvoter_ids: options[:user].id.to_s } }
          when 'downvotes' then { term: { downvoter_ids: options[:user].id.to_s } }
          when 'uploads'   then { term: { true_uploader_id: options[:user].id.to_s } }
          when 'hidden'    then { term: { hidden_by_user_ids: options[:user].id.to_s } }
          when 'watched'
            raise SearchParsingError, 'Recursive watchlists are not allowed.' if options[:watch]

            user = options[:user]
            should = []
            must_not = []

            tag_include_query = { terms: { tag_ids: user.watched_tag_ids } }
            include_query = Image.get_search_parser(user.watched_images_query, options.merge(watch: true)).parsed
            exclude_query = Image.get_search_parser(user.watched_images_exclude_query, options.merge(watch: true)).parsed

            should.push(tag_include_query) if user.watched_tag_ids.any?
            should.push(include_query) if include_query.present?
            must_not.push(exclude_query) if exclude_query.present?

            if user.current_filter && user.no_spoilered_in_watched
              spoiler_tag_exclude_query = { terms: { tag_ids: user.current_filter.spoilered_tag_ids } }
              spoiler_exclude_query = Image.get_search_parser(user.current_filter.normalized_spoilered_complex_str, options.merge(watch: true)).parsed

              must_not.push(spoiler_tag_exclude_query) if user.current_filter.spoilered_tag_ids.any?
              must_not.push(spoiler_exclude_query) if spoiler_exclude_query.present?
            end

            { bool: { should: should, must_not: must_not } }
          else raise SearchParsingError, "Invalid 'my' term 'my:#{x}'."
          end
        end,
        gallery_id: ->(x) do
          int = Integer(x) rescue nil
          raise SearchParsingError, 'gallery_id must be an integer.' if int.nil?

          { nested: { path: :galleries, query: { term: { 'galleries.id': x } } } }
        end
      }
    end

    # In addition to the option keys supported by the base method,
    # Image#fancy_search also supports these additional, very important,
    # options:
    # * hidden_tags: An array of tag IDs to hide.
    # * hidden: A pre-compiled query or filter hash for hiding images
    #           through more complex criteria.
    # * last: Earliest created-at time for results.
    # * last_first_seen: Earliest first-seen-at time for results (created-at
    #                    time not of an image's earliest iteration prior to
    #                    deduplication).
    # Note these options may also be specified in the scoped search_params,
    # but separating them allows for user customization after the fact.
    def fancy_search(options, &block)
      super(options) do |s|
        yield s if block

        # Hidden tag filtering.
        s.add_filter(bool: { must_not: { terms: { tag_ids: options[:hidden_tags] } } }) if options[:hidden_tags].present?

        # Hidden query filtering.
        hidden_search = options[:hidden].presence
        s.add_filter(bool: { must_not: hidden_search }) if !hidden_search.nil?

        s.add_filter(range: { created_at: { gt: options[:last] } }) if options[:last]

        s.add_filter(range: { first_seen_at: { gt: options[:last_first_seen] } }) if options[:last_first_seen]

        if options[:include_deleted] == :only
          s.add_filter(term: { hidden_from_users: 'true' })
        elsif !(options[:include_deleted])
          s.add_filter(term: { hidden_from_users: 'false' })
        end
      end
    end

    def default_sort(_options = {})
      [created_at: :desc]
    end
  end

  def as_json(options = {})
    # Fields always present
    d = {
      id:            id,
      created_at:    created_at,
      updated_at:    updated_at,
      first_seen_at: first_seen_at,
      tags:          tag_list,
      tag_ids:       tag_ids
    }
    d[:uploader_id] = nil
    d[:uploader_id] = user_id if user_id && !anonymous

    if hidden_from_users
      if duplicate_id
        d[:duplicate_of] = duplicate_id
      else
        d[:deletion_reason] = deletion_reason || 'None specified'
      end
    else
      d.merge! as_compact_indexed_json(omit_galleries: true)
      d[:file_name] = image_name.to_s
      d[:description] = description.to_s
      d[:uploader] = uploader
      d[:image] = image.pretty_url rescue nil
      d[:upvotes] = upvotes_count
      d[:downvotes] = downvotes_count
      d[:faves] = faves_count
      d[:aspect_ratio] = image_aspect_ratio
      d[:original_format] = image_format&.downcase.to_s
      d[:mime_type] = image_mime_type
      d[:sha512_hash] = image_sha512_hash
      d[:orig_sha512_hash] = image_orig_sha512_hash
      d[:source_url] = source_url
      d[:comments] = Comment.includes(:user).where(id: comment_ids) if options[:comments]
      d[:favourited_by_users] = faves.includes(:user).map { |f| f.user.name } if options[:fav]
      d[:representations] = image.view_urls
      d[:is_rendered] = thumbnails_generated?
      d[:is_optimized] = processed?
    end
    d
  end

  # Only includes fields that are sortable
  def as_compact_indexed_json(options = {})
    d = {
      id:            id,
      created_at:    created_at,
      score:         score,
      comment_count: comments_count,
      width:         image_width.to_i,
      height:        image_height.to_i,
      tag_count:     tag_ids.size
    }
    d[:galleries] = gallery_interactions.map(&:image_index) unless options[:omit_galleries]
    d
  end

  # For Elasticsearch
  def as_indexed_json(*)
    {
      id:                     id,
      upvotes:                upvotes_count,
      downvotes:              downvotes_count,
      score:                  score,
      faves:                  faves_count,
      comment_count:          comments_count,
      width:                  image_width,
      height:                 image_height,
      tag_count:              tag_ids.size,
      aspect_ratio:           image_aspect_ratio,
      wilson_score:           wilson_score,
      created_at:             created_at,
      updated_at:             updated_at,
      first_seen_at:          first_seen_at,
      ip:                     ip.to_s,
      tag_ids:                tag_ids,
      mime_type:              image_mime_type,
      uploader:               (user.name.downcase if user && !anonymous),
      true_uploader:          (user.name.downcase if user),
      source_url:             source_url.presence&.downcase,
      file_name:              image_name&.downcase,
      original_format:        image_format&.downcase,
      fingerprint:            fingerprint,
      uploader_id:            (user_id if user_id && !anonymous),
      true_uploader_id:       user_id,
      image:                  (image.pretty_url rescue nil),
      orig_sha512_hash:       image_orig_sha512_hash,
      sha512_hash:            image_sha512_hash,
      hidden_from_users:      hidden_from_users,
      anonymous:              anonymous,
      is_optimized:           thumbnails_generated?,
      is_rendered:            processed?,
      description:            description,
      deletion_reason:        deletion_reason,

      favourited_by_user_ids: faves.map(&:user_id),
      hidden_by_user_ids:     hides.map(&:user_id),
      upvoter_ids:            upvotes.map(&:user_id),
      downvoter_ids:          downvotes.map(&:user_id),
      deleted_by_user_id:     deleted_by_id,

      galleries:              gallery_interactions.map(&:image_index),

      namespaced_tags:        { name: tags.flat_map { |t| [t, *t.aliases] }.map(&:name) },
      favourited_by_users:    faves.map     { |f| f.user.name.downcase },
      hidden_by_users:        hides.map     { |h| h.user.name.downcase },
      upvoters:               upvotes.map   { |v| v.user.name.downcase },
      downvoters:             downvotes.map { |v| v.user.name.downcase },
      deleted_by_user:        deleted_by&.name&.downcase
    }
  end
end
