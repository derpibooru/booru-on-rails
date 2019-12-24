# frozen_string_literal: true

module ReportsHelper
  def reported_thing(reportable)
    case reportable
    when NilClass then 'Reported item permanently deleted.'
    when Channel then "Channel '#{reportable.title}'"
    when Comment then "Comment on >>#{reportable.image_id} by '#{reportable.author}'"
    when Commission then "#{reportable.user.name}'s commission sheet"
    when Conversation then "Conversation between '#{reportable.from.name}' and '#{reportable.to.name}'"
    when Gallery then "Gallery ##{reportable.id}"
    when Filter then "Filter '#{reportable.name}'"
    when Image then "Image ##{reportable.id}"
    when Post then "Post by '#{reportable.author}' in topic '#{reportable.topic.title}'"
    when User then "User #{reportable.name}"
    end
  end

  def link_to_reported_thing(reportable)
    text = reported_thing(reportable)
    return text if reportable.nil?

    render partial: "reports/#{reportable.class.to_s.downcase}", locals: { reportable: reportable, text: text }
  end
end
