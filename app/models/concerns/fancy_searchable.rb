# frozen_string_literal: true

require 'search_parser'
module FancySearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
  end

  class FancySearchableOptions
    attr_reader :queries, :filters, :sorts
    attr_accessor :size, :from

    def initialize(options = {})
      @queries = []
      @filters = []
      @sorts   = []

      (options[:queries] || []).each { |q| add_query(q)  }
      (options[:filters] || []).each { |f| add_filter(f) }
      (options[:sorts]   || []).each { |s| add_sort(s)   }

      # Default size is 15 records, offset 0
      @size = options[:size] || 15
      @from = options[:from] || 0
    end

    def add_query(query)
      @queries.push(query)
    end

    def add_filter(filter)
      @filters.push(filter)
    end

    def add_sort(sort)
      if sort[:_random]
        @queries.push(function_score: {
          query:        { match_all: {} },
          random_score: { seed: sort[:random_seed] || rand(4_294_967_296) },
          boost_mode:   :replace
        })
        @sorts.unshift(_score: sort[:_random])
      else
        @sorts.push(sort)
      end
    end
  end

  class_methods do
    def index_fields_mapping
      @index_fields_mapping ||= __elasticsearch__.mappings.to_hash[
        __elasticsearch__.document_type.to_sym
      ][:properties]
    end

    def allowed_search_fields(_access_options = {})
      index_fields_mapping.keys
    end

    def get_field_type_map(allowed_fields)
      field_type_map = { literal: [], float: [], full_text: [],
                         date: [], integer: [], ip: [], boolean: [] }
      allowed_fields.each do |field|
        trufield = field_aliases.key?(field) ? field_aliases[field] : field
        mapping = index_fields_mapping[trufield]
        dtype = mapping && mapping[:type]&.to_sym
        # Index mapping for search field missing.
        if dtype.nil?
          field_type_map[:literal].push field
        elsif dtype == :keyword
          field_type_map[:literal].push field
        elsif dtype == :boolean
          field_type_map[:boolean].push field
        elsif dtype == :ip
          field_type_map[:ip].push field
        elsif dtype == :text
          field_type_map[:full_text].push field
        elsif dtype == :date
          field_type_map[:date].push field
        elsif dtype == :integer
          field_type_map[:integer].push field
        else
          field_type_map[:float].push field
        end
      end
      field_type_map
    end

    # Field aliasing.
    def field_aliases
      {}
    end

    # Value transformations Hash: String => Lambda.
    def field_transforms(_options = {})
      {}
    end

    def default_field
      :'namespaced_tags.name'
    end

    def default_query(_options = {})
      { match_all: {} }
    end

    def default_sort(_options = {})
      []
    end

    def no_downcase_fields
      []
    end

    def get_search_parser(query, access_options = nil)
      # Invokes the associated SearchParser appropriate to the model.
      SearchParser.new(
        query,
        default_field,
        allowed_fields:   get_field_type_map(
          allowed_search_fields((access_options || {}))
        ),
        field_aliases:    field_aliases,
        field_transforms: field_transforms(access_options || {}),
        no_downcase:      no_downcase_fields
      )
    end

    # Main fancy_search function. Provides tire-like search API:
    #
    # response = Image.fancy_search(size: 25) do |search|
    #   search.add_filter term: { hidden_from_users: false }
    #   search.add_sort :created_at => :desc
    # end
    # @images = response.records
    #
    def fancy_search(options = {})
      searchable_options = FancySearchableOptions.new(options)

      yield searchable_options if block_given?

      if options[:query]
        parser = get_search_parser(options[:query], options[:access_options])

        if parser.requires_query
          searchable_options.add_query parser.parsed
        else
          searchable_options.add_filter parser.parsed
        end
      end

      sorts   = searchable_options.sorts
      queries = searchable_options.queries
      filters = searchable_options.filters

      sorts = default_sort if sorts.empty?

      queries = default_query if queries.empty?

      search_body = {
        query:   { bool: { must: queries, filter: filters } },
        sort:    sorts,
        _source: false
      }

      size = (options[:size] || options[:per_page] || 25).to_i

      # Response is lazily evaluated.
      if options[:from]
        search(search_body.merge(size: size, from: options[:from].to_i))
      elsif options[:page]
        search(search_body).page(options[:page].to_i).per(size)
      else
        search(search_body.merge(size: size, from: 0))
      end
    end
  end
end
