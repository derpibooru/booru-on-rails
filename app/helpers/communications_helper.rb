# frozen_string_literal: true

require 'English'
require 'simpletextile'

module CommunicationsHelper
  def render_textile(text, fancy = false)
    parser = SimpleTextile.new.default_match
    image_on_site_link_pattern = /&gt;&gt;(?<id>\d+)(?<type>[pts]?)/
    parser.match(image_on_site_link_pattern) do |img_text|
      # Stupid, but the parser doesn't give us capture group information
      img_text.gsub(image_on_site_link_pattern) do
        id = $LAST_MATCH_INFO[:id].to_i
        image = get_image_or_merge_target(id)
        if $LAST_MATCH_INFO[:type] == 'p' && fancy
          render partial: 'images/image_container_filterable', locals: { image: image, size: :medium }
        elsif $LAST_MATCH_INFO[:type] == 't' && fancy
          render partial: 'images/image_container_filterable', locals: { image: image, size: :small }
        elsif $LAST_MATCH_INFO[:type] == 's' && fancy
          render partial: 'images/image_container_filterable', locals: { image: image, size: :thumb_small }
        else
          link_to ">>#{id}", short_image_path(image) rescue img_text
        end
      end
    end
    text = parser.parse(text)
    text.html_safe
  end

  def render_post(post)
    html = render_textile(post.body, true)
    html.html_safe
  end

  def safe_author(post)
    # If user has textile markup in the name (looking at you, -_-_-_-_-)
    # escape it with brackets
    parser = SimpleTextile.new.default_match
    author = post.author
    parsed = parser.parse("\"@#{author}\":/")

    if parsed != "<a href=\"/\">@#{author}</a>"
      # Cover *all* possibilities.
      author = "[==#{author.gsub(/==\]/, '==]==][==')}==]"
    end

    author
  end

  def editable_communications(communications)
    communications&.select { |c| current_user&.can? :edit, c }&.map(&:id)
  end
end
