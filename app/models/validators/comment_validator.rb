# frozen_string_literal: true

class CommentValidator < ActiveModel::Validator
  def validate(record)
    max_comment_length = Booru::CONFIG.settings[:max_comment_length]
    record.errors[:base] << "Too long (#{max_comment_length} characters max)." if max_comment_length && record.body.length > max_comment_length
    record.errors[:base] << 'You need to be logged in to post a comment with links in it.' if record.user.nil? && (['<a', '[url]', 'www.', 'http://'].any? { |link_indicator| record.body.include?(link_indicator) })
  end
end
