# frozen_string_literal: true

module Sluggable
  extend ActiveSupport::Concern

  included do
    class_attribute :slugged_field
    validates :slug, uniqueness: true
  end

  class_methods do
    def generate_slug(name)
      new_name = name.clone

      # Escape common punctuation.
      new_name.gsub!('-', '-dash-')
      new_name.gsub!('/', '-fwslash-')
      new_name.gsub!('\\', '-bwslash-')
      new_name.gsub!(':', '-colon-')
      new_name.gsub!('.', '-dot-')
      new_name.gsub!('+', '-plus-')

      # Render into URL encoding. For URLs dipsit.
      CGI.escape(new_name).gsub('%20', '+')
    end

    #
    # Finds the Sluggable corresponding to some passed slug, with fallback
    # for IDs and legacy non-encoded slugs.
    # 1: Try the slug.
    # 2: Maybe we already escaped the slug (backwards compatibility).
    # 3: The slug has failed. If we have an integer, try the ID, for backwards
    #    compatibility.
    # Because most cases are expected to be 1, it is done in a single
    # small query. Failing that, cases 2 and conditionally 3 are handled in
    # the following query.
    def find_by_slug_or_id(slug_or_id)
      sluggable = find_by(slug: slug_or_id)
      return sluggable if sluggable

      cgi_escaped = CGI.escape(slug_or_id).gsub('%2B', '+')
      if slug_or_id.match?(/\A\d+\z/)
        find_by('slug = ? OR id = ?', cgi_escaped, slug_or_id.to_i)
      else
        find_by(slug: cgi_escaped)
      end
    end

    def set_slugged_field(field_name)
      self.slugged_field = field_name.to_sym
    end
  end

  def set_slug
    self.slug = self.class.generate_slug(send(slugged_field)) if slug.nil? || changed_attribute_names_to_save.include?(slugged_field.to_s)
  end
end
