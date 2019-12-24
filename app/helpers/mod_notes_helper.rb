# frozen_string_literal: true

module ModNotesHelper
  def noted_thing(notable)
    case notable
    when NilClass then 'Item permanently deleted'
    when User then "User '#{notable.name}'"
    when DnpEntry then "#{notable.requesting_user.name}'s DNP Request"
    when Report then "Report on #{reported_thing notable.reportable}"
    end
  end

  def link_to_noted_thing(notable)
    text = noted_thing(notable)
    return text if notable.nil?

    render partial: "admin/mod_notes/#{notable.class.to_s.downcase}", locals: { notable: notable, text: text }
  end
end
