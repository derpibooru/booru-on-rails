# frozen_string_literal: true

class ImageLoader
  attr_reader :options

  def initialize(options = {})
    @options = options.clone
    if @options[:sample]
      @options[:size] = 1
      @options[:from] = 0
      @options[:sorts] = [_random: :desc]
    end
  end

  def index
    Image.fancy_search(@options)
  end

  def search(query)
    Image.fancy_search(@options.merge(query: query))
  end

  def tag(tag)
    Image.fancy_search(@options) do |s|
      s.add_filter term: { tag_ids: tag.id.to_s }
    end
  end

  def gallery(gallery_id, image_order = :desc)
    Image.fancy_search(@options) do |s|
      s.add_filter nested: {
        path:  :galleries,
        query: { bool: { must: [{ match: { 'galleries.id': gallery_id } }] } }
      }
      s.add_sort 'galleries.position': {
        order:         image_order,
        nested_path:   :galleries,
        nested_filter: { term: { 'galleries.id': gallery_id } }
      }
    end
  end

  # We get consecutive images by finding all images greater than or less than
  # the current image, and grabbing the FIRST one
  RANGE_COMPARISON_FOR_ORDER = {
    asc: :gt, desc: :lt
  }.freeze

  # If we didn't reverse for prev, it would be the LAST image, which would
  # make ElasticSearch choke on deep pagination
  ORDER_FOR_DIR = {
    next: { asc: :asc,  desc: :desc }.freeze,
    prev: { asc: :desc, desc: :asc  }.freeze
  }.freeze

  def find_consecutive(id, rel)
    # Load the image data as seen by ElasticSearch
    img = Image.find_by(id: id)&.as_compact_indexed_json
    return nil if img.nil?

    search = Image.fancy_search(@options.merge(from: 0, size: 1)) do |s|
      filters = []

      s.sorts.each do |sort|
        if sort['galleries.position']
          # Extract gallery ID and current position
          gid = sort['galleries.position']['nested_filter']['term']['galleries.id']
          pos = img[:galleries].find { |g| g[:id] == gid }[:position]

          # Sort in the other direction if we are going backwards
          sort_dir = sort['galleries.position']['order']
          sort['galleries.position']['order'] = sort_order = ORDER_FOR_DIR[rel][sort_dir]

          # Now add a range filter to get all images greater/less than this
          filters.push(GalleryRangeFilter.new(RANGE_COMPARISON_FOR_ORDER[sort_order], pos))
        else
          # Extract sort field and direction
          sf, sort_dir = sort.to_a[0].map(&:to_sym)

          # Sort in the other order if we are going backwards
          sort[sf] = sort_order = ORDER_FOR_DIR[rel][sort_dir]

          # Now add a range filter to get all images greater/less than this
          filters.push(RangeFilter.new(sf, RANGE_COMPARISON_FOR_ORDER[sort_order], img[sf])) if ![:_random, :_score].include?(sf)
        end
      end

      s.add_filter(bool: { should: sortify(filters), must_not: { term: { id: id } } })
    end

    search.results[0]
  rescue StandardError => ex
    Rails.logger.error ex.inspect
    nil
  end

  def find_prev(id)
    find_consecutive(id, :prev)
  end

  def find_next(id)
    find_consecutive(id, :next)
  end

  def sortify(filters)
    filters.each_with_index.map do |f, i|
      next f.for_this if i == 0

      { bool: { must: [f.for_this, filters[0...i].map(&:for_next)].flatten } }
    end
  end

  RANGE_MAP = {
    gt: :gte,
    lt: :lte
  }.freeze

  class RangeFilter
    def initialize(sf, dir, val)
      @sf  = sf
      @dir = dir
      @val = val
    end

    def for_this
      { range: { @sf => { @dir => @val } } }
    end

    def for_next
      { range: { @sf => { RANGE_MAP[@dir] => @val } } }
    end
  end

  class GalleryRangeFilter
    def initialize(dir, val)
      @dir = dir
      @val = val
    end

    def for_this
      {
        nested: {
          path:  :galleries,
          query: { range: { 'galleries.position': { @dir => @val } } }
        }
      }
    end

    def for_next
      {
        nested: {
          path:  :galleries,
          query: { range: { 'galleries.position': { RANGE_MAP[@dir] => @val } } }
        }
      }
    end
  end
end
