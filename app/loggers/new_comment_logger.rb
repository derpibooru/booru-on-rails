# frozen_string_literal: true

class NewCommentLogger < LoggerBase
  def self.log(comment)
    s = +"[COMMENT: New on ##{comment.image_id}]"
    s += " #{Booru::CONFIG.settings[:public_url_root]}#{comment.link_to_route}"
    s += " by #{comment.author}"
    s += " - body: #{sanitize_newlines(comment.body)[0...100]}"

    livefeed_send(s)
  end
end
