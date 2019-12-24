# frozen_string_literal: true

class CommentQuery
  def self.paginate(image:, current_user:, page:, comment_id: nil)
    comment_id ||= image.comments.last&.id if should_show_last_page?(page, current_user)
    per_page = current_user&.comments_per_page || 20
    comments = comment_relation(image, current_user)

    if comment_id.present?
      comment = Comment.find_by(id: comment_id)
      time = comment&.created_at || Time.zone.at(0)

      offset = if sort_direction(current_user) == :asc
        comments.where('created_at < ?', time).count
      else
        comments.where('created_at > ?', time).count
      end

      # Pagination starts at 1, not 0.
      page = (offset / per_page) + 1
    else
      page = page.to_i
    end

    comments.page(page).per(per_page)
  end

  def self.comment_relation(image, user)
    relation = Comment.where(image: image).includes(:image, :user).order(created_at: sort_direction(user))
    relation = relation.where(destroyed_content: false) unless user && user.can?(:manage, Comment)
    relation
  end

  def self.sort_direction(user)
    return :desc if user.nil? || user.comments_newest_first

    :asc
  end

  def self.should_show_last_page?(page, user)
    # TODO: this sucks
    page_not_specified = page == '0' # set in the view code for the initial comments fetch
    page_not_specified && user&.comments_always_jump_to_last
  end
end
