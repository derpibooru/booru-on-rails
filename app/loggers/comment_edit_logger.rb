# frozen_string_literal: true

class CommentEditLogger < LoggerBase
  def self.log(comment, user)
    return if comment.previous_changes[:body].nil?

    old_body = comment.previous_changes[:body].first
    new_body = comment.body

    updater = if user == comment.user
      comment.author
    else
      user&.name
    end

    s = +"[COMMENT: Edited on ##{comment.image_id}] #{Booru::CONFIG.settings[:public_url_root]}#{comment.link_to_route} by #{updater}"
    s += " - new: #{sanitize_newlines(new_body)[0...100]}"
    s += " - old: #{sanitize_newlines(old_body)[0...100]}"
    s += " - reason: #{comment.edit_reason}"

    livefeed_send(s)
  end
end
