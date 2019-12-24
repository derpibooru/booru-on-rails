# frozen_string_literal: true

require 'anony_hash'

module AuthorHelper
  include AnonyHash

  def link_to_author(object, reveal_anon = false)
    reveal_anon = reveal_anon ? (cookies['hidestaff'] != 'true') : reveal_anon

    if object.user_visible?
      link_to object.user.name, profile_path(object.user.slug)
    elsif object.user && reveal_anon
      link_to object.author(reveal_anon), profile_path(object.user.slug)
    else
      object.author(reveal_anon)
    end
  end

  def user_avatar(user, klass = 'avatar--125px', displayedname = 'an unknown user')
    content_tag :div, class: "image-constrained #{klass}" do
      if user&.avatar&.present?
        image_tag user.uploaded_avatar.url, alt: "#{user.name}'s avatar"
      else
        oc_avatar_generator(displayedname)
      end
    end
  end

  # Return an IP dropdown
  def link_to_ip(ip, cidr = false)
    link_to content_tag(:em, (cidr ? ip.to_cidr : ip.to_s)), "/ip_profiles/#{ip}", class: 'js-staff-action'
  end

  def link_to_fingerprint(fingerprint, user_agent = nil)
    if fingerprint
      link_to content_tag(:code, fingerprint[0..6].to_s, title: user_agent), "/fingerprint_profiles/#{fingerprint}", class: 'js-staff-action'
    else
      content_tag(:code, 'null', title: 'This must be from before this had fingerprints.')
    end
  end

  #
  # Get an abbreviation for a given user
  # @param  user [User] The user to abbreviate for, or nil
  #
  def user_abbrv(user)
    s = ''
    if user
      # try initials
      abbr = user.name.split[0..3].map { |x| x.chars.first }.join
      if !abbr || abbr.length < 2
        # try uppercase letters
        abbr = user.name.chars.grep(/[A-Z]/)[0..3].join
        if !abbr || abbr.blank?
          # kay, just take the first four letter I guess
          abbr = user.name[0..3].upcase
        end
      end
      abbr = user.name.split(' ').map { |w| w[0] }.join.upcase if abbr.size == 1
      s = abbr.to_s
    else
      s = 'n/a'
    end

    if user
      link_to content_tag(:span, "(#{s})", title: user&.name), profile_path(user.slug), class: 'js-staff-action'
    else
      content_tag(:span, "(#{s})")
    end
  end

  def user_label(user, small: false)
    return nil unless user

    staff_role_tag =
      if user.hide_default_role?
        # If the 'Hide staff title' box is checked, then just skip staff_role_tag
        ''.html_safe
      else
        case user.role
        when 'admin'
          content_tag(:div, class: "label label--danger label--block #{'label--small' if small}") { 'Site Administrator' }
        when 'moderator'
          content_tag(:div, class: "label label--success label--block #{'label--small' if small}") { 'Site Moderator' }
        when 'assistant'
          content_tag(:div, class: "label label--purple label--block #{'label--small' if small}") { 'Site Assistant' }
        else
          ''.html_safe
        end
      end

    secondary_role_tag = user.secondary_role.present? ? content_tag(:div, class: "label label--warning label--block #{'label--small' if small}") { user.secondary_role } : ''.html_safe
    personal_title_tag = user.personal_title.present? ? content_tag(:div, class: "label label--primary label--block #{'label--small' if small}") { user.personal_title } : ''.html_safe
    role_tag = staff_role_tag + secondary_role_tag + personal_title_tag

    role_tag
  end
end
