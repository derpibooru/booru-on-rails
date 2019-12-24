# frozen_string_literal: true

module TagsHelper
  def tag_info
    return ''.html_safe if @ignoredtaglist.blank?

    return render partial: 'images/imagelist_tags_row' if @ignoredtaglist.size > 1

    tag = @ignoredtaglist[0]
    show_public_links_only = cannot? :manage, UserLink
    associated_links = tag.associated_links(show_public_links_only)
    links_updated_at = associated_links.map(&:updated_at).max
    implied_by_tags = Tag.joins(:implied_tags).where(tags_implied_tags: { implied_tag_id: tag.id })
    implied_by_tag_ids = implied_by_tags.pluck(:id)
    cache_string = "tag-info-v1-#{tag.id}-#{tag.updated_at}-#{links_updated_at}-#{show_public_links_only}-#{implied_by_tag_ids}"
    # damn son that's a lot of locals
    render partial: 'images/imagelist_tag_info_row', locals: {
      aliased_tags:     tag_alias_list(tag),
      implied_tags:     tag_implied_list(tag),
      implied_by_tags:  linked_tag_list(implied_by_tags.sort_by(&:name)),
      associated_links: associated_links.map { |l| link_to h(l.uri), h(l.uri) }.join(', ').html_safe,
      associated_users: tag.associated_users(show_public_links_only).map { |u| link_to h(u.name), profile_path(u) }.join(', ').html_safe,
      cache_string:     cache_string # rails caching breaks in non-obvious ways when used in helpers
    }
  end

  def random_image_path
    search_path(scope_key.merge(random_image: 'y'))
  end

  def tag_alias_list(tag)
    aliased_tags = Tag.where(aliased_tag_id: tag.id).order(name: :asc)
    if can? :manage, tag
      aliased_tags.map { |t| link_to(t.name, edit_admin_tag_path(t)) }.join(', ').html_safe
    else
      aliased_tags.pluck(:name).join(', ')
    end
  end

  def tag_implied_list(tag)
    linked_tag_list tag.implied_tags.sort_by(&:name)
  end

  def linked_tag_list(tags)
    tags.map { |t| link_to(t.name, tag_path(t)) }.join(', ').html_safe
  end

  def implied_by_multitag(tag_names, ignore_tag_names = [])
    tag_ids = Tag.where(name: tag_names).select(:id)
    ignore_tag_ids = Tag.where(name: ignore_tag_names).select(:id)

    Tag.joins(:implied_tags)
       .preload(:implied_tags)
       .where(tags_implied_tags: { implied_tag_id: tag_ids })
       .where.not(tags_implied_tags: { implied_tag_id: ignore_tag_ids })
       .order(images_count: :desc)
       .limit(40)
  end

  def print_tag_link(tag, tag_name)
    return h(tag_name) if tag.nil?

    implied_tags = nil

    implied_tags = "Implies: #{tag.implied_tags.map(&:name).sort.join(', ')}" if tag.implied_tags.any?

    title = [tag.short_description.presence, implied_tags].compact.join("\n").presence
    link_to(tag_name, '#', title: title, data: { 'tag-name' => tag_name, 'click-addtag' => tag_name })
  end
end
