# frozen_string_literal: true

module ApplicationHelper
  def render_time
    diff = ((Time.zone.now - @start_time) * 1000.0).round(2)
    diff < 1000 ? "(#{diff}ms)" : "(#{(diff / 1000.0).round(2)}s)"
  rescue StandardError
    '(nil ms)'
  end

  # Returns a string like: "Displaying <plural of class> <1 + ((current-page-1) * per-page)> - <that number plus per-page> of <total>"
  # given a set of tire results
  def pagination_info(results)
    return 'No results to display' if results.total_count == 0

    s = ("<span class=\"hide-mobile\">Showing #{results.model.to_s.pluralize.downcase} </span>" rescue '<span class="hide-mobile">Showing results </span>')
    first_item = 1 + ((results.current_page - 1) * @per_page)
    last_item = first_item + @per_page - 1
    last_item = results.total_count if last_item > results.total_count
    s += ('<strong>' + first_item.to_s + '</strong> - <strong>' + last_item.to_s + '</strong>')
    s += " of <strong>#{results.total_count}</strong> total"
    s.html_safe
  end

  def friendly_time(time)
    return "<time datetime=#{time.utc.iso8601}>#{time.strftime('%H:%M, %B %d, %Y')}</time>".html_safe if time

    'an unknown time ago'
  end

  # Cache unless we're an admin
  # triggers a cancan check on first + second arg
  # Other args are as you'd expect for cache, ie:
  # cache_unless_can(:manage, Image, "image_#{image.id}", expires_in: 3600)
  def cache_unless_can(*args)
    t = args.shift
    m = args.shift
    cache_unless can?(t, m), args do
      yield
    end
  end

  def pretty_bignumber(number, digits)
    f = format("%.#{digits - 1}e", number).to_f
    i = f.to_i
    number_with_delimiter(i == f ? i : f)
  end

  # Inserts a link with text next to an icon. The usage is similar to +link_to+ except that the
  # second argument is a string representing the icon class(es). Example:
  #
  # icon_link_to "Awesome!", "fa fa-thumbs-up", awesome_path, id: "awesome-id", class: "awesome-class"
  # => <a href="/awesome" class="awesome-class" id="awesome-id"><i class="fa fa-thumbs-up"></i> Awesome!</a>
  #
  # Pass :responsive as an option to add "hide-mobile" class to the link text.
  def icon_link(name = nil, icon_class = nil, options = nil, html_options = nil, &block)
    link_to options, html_options do
      concat content_tag :i, '', class: icon_class
      if html_options && html_options[:responsive]
        concat content_tag :span, " #{name}", class: 'hide-mobile'
      elsif name.present?
        concat " #{name}"
      end
      concat capture(&block) if block_given?
    end
  end

  # Inserts a Subscribe/Unsubscribe link supported by +notifications.js+.
  def subscription_link(object, user, options = {})
    user_is_watching = Notification.watching?(object, user)

    # FIXME: a hack for LivestreamChannel to have Channel as _class that will shoot me (or you) in the foot at some point
    object_class = (object.class.superclass == ApplicationRecord ? object.class.name : object.class.superclass.name).to_s
    object_id = object.id.to_s

    subscribe_options = options.deep_merge(
      class: [options[:class], 'js-notification-' + object_class + object_id, ('hidden' if user_is_watching)],
      data:  { subscription_type: object_class, subscription_id: object_id, click_togglesubscription: 'watch' }
    )

    unsubscribe_options = options.deep_merge(
      class: [options[:class], 'js-notification-' + object_class + object_id, ('hidden' if !user_is_watching)],
      data:  { subscription_type: object_class, subscription_id: object_id, click_togglesubscription: 'unwatch' }
    )

    concat icon_link 'Subscribe', 'far fa-bell', '#', subscribe_options
    icon_link 'Unsubscribe', 'far fa-bell-slash', '#', unsubscribe_options
  end

  def page_layout(type)
    content_for(:page_layout_class) do
      case type
      when :wide
        'layout--wide'
      when :medium
        'layout--medium'
      end
    end
  end
end
