# frozen_string_literal: true

module ImagesHelper
  def image_container_data(image)
    display_hidden = image.hidden_from_users? && image.can_see_when_hidden?(current_user)
    {
      'image-id'          => image.id,
      'image-tags'        => image.tag_ids.to_json,
      'image-tag-aliases' => image.tag_list_plus_alias,
      'score'             => image.score,
      'faves'             => image.faves_count,
      'upvotes'           => image.upvotes_count,
      'downvotes'         => image.downvotes_count,
      'comment-count'     => image.comments_count,
      'created-at'        => image.created_at.iso8601,
      'source-url'        => image.source_url,
      'uris'              => image.image.view_urls(hidden: display_hidden).to_json,
      'width'             => image.image_width,
      'height'            => image.image_height,
      'aspect-ratio'      => image.image_aspect_ratio
      # 'download-uri'      => image.image.pretty_url(download: true),
      # 'sha512'            => image.image_sha512_hash,
      # 'orig-sha512'       => image.image_orig_sha512_hash
    }
  end

  # Returns a link to the image preview (:medium) or, if the image is spoilered, to the tag image.
  def spoilered_preview(image, filter)
    spoilered_tag = filter.image_spoiler_tag(image)
    if image.thumbnails_generated?
      if spoilered_tag
        spoilered_tag.spoiler_image_uri || "#{Booru::CONFIG.settings[:cdn_url_root]}/tagblocked.svg"
      else
        see_hidden = image.hidden_from_users && image.can_see_when_hidden?(current_user)
        image.image.url(:medium, hidden: see_hidden)
      end
    else
      path_to_image('loading/800x600.jpg')
    end
  end

  def display_image(id)
    i = Image.find_by(id: id)
    render partial: 'images/display_images', locals: { images: [i] }
  end

  def hidden_image_link(html)
    href = /href="([^"]*)"/.match(html)[1] rescue nil
    src = /src="([^"]*)"/.match(html)[1] rescue ''
    alt = /alt="([^"]*)"/.match(html)[1] rescue ''

    # All of these have been html-escaped already.
    linktxt = href ? " <a href=\"#{href}\"> (linked to here)</a>" : ''
    "<span title=\"#{src}\" class=\"hidden-image\">Image hidden - <a class=\"show-hidden-image\" href=\"#{src}\" title=\"#{alt}\">click to view</a>#{linktxt}</span>"
  end

  # Toggle link for deleted images in image list pages.
  def toggle_deleted_images
    if can?(:undelete, Image) && (cookies['hidestaff'] != 'true')
      deletion_switch_arg = params[:del]
      markups = []
      if deletion_switch_arg.present?
        markups.push link_to('<i class="fa fa-minus"></i><i class="fa fa-exclamation"></i> <span class="hide-mobile hide-limited-desktop">Hide Deleted</span>'.html_safe,
                             params.permit!.merge(del: nil), title: 'Hide Deleted/Merged Images')
      else
        markups.push link_to('<i class="fa fa-plus"></i><i class="fa fa-exclamation"></i> <span class="hide-mobile hide-limited-desktop">Show Deleted</span>'.html_safe,
                             params.permit!.merge(del: 1), title: 'Include Deleted/Merged Images')
      end
      if deletion_switch_arg == 'only'
        markups.push link_to('<i class="fa fa-plus"></i><i class="fa fa-check"></i> <span class="hide-mobile hide-limited-desktop">Show Non-Deleted</span>'.html_safe,
                             params.permit!.merge(del: 1), title: 'Include Images Visible to Users')
      else
        markups.push link_to('<i class="fa fa-minus"></i><i class="fa fa-check"></i> <span class="hide-mobile hide-limited-desktop">Only Deleted</span>'.html_safe,
                             params.permit!.merge(del: 'only'), title: 'Only Deleted/Merged Images')
      end
      markups.join(' ').html_safe
    end
  end

  def deleted_images_dropdown(additional_class = nil)
    selected = if @include_deleted.blank?
      ''
    elsif @include_deleted == :only
      'only'
    else
      '1'
    end
    options = options_for_select([
      [t('images.search.exclude_deleted'), '', { title: t('images.search.exclude_deleted_title') }],
      [t('images.search.include_deleted'), '1', { title: t('images.search.include_deleted_title') }],
      [t('images.search.deleted_only'), 'only', { title: t('images.search.deleted_only_title') }]
    ], selected)
    select_tag :del, options, autocomplete: 'off', class: "input #{additional_class}"
  end

  def get_image_or_merge_target(id)
    image = Image.find_by(id: id)
    if image&.duplicate_id
      Image.find_by(id: image.duplicate_id)
    else
      image
    end
  end
end
