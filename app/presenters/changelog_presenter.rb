# frozen_string_literal: true

class ChangelogPresenter
  # Gets the most recent commits.
  # @return [Enumerable<CommitInfo>]
  def commits
    @commits ||= Booru::CommitHistory.new.take(20)
  end

  # Gets a mapping of email addresses to known users from
  # the last 20 commits.
  #
  # @return [Hash<String, User>]
  def users
    @users ||= User.where(email: emails).index_by(&:email)
  end

  # Email addresses of the last 20 commit authors.
  # @return [Array<String>]
  def emails
    @emails ||= commits.map(&:email)
  end

  # Gets the user name for an email address,
  # @return [String]
  def user_name(email)
    users[email]&.name
  end

  # Gets the author name for a commit.
  # @return [String]
  def author_name(commit)
    user_name(commit.email) || commit.name
  end

  # Gets the user name for a commit, or "Someone" if
  # the user is not known.
  #
  # @return [String]
  def display_name(commit)
    user_name(commit.email) || 'Someone'
  end

  # Gets commits in JSON format.
  # @return [Hash]
  def as_json
    rendered = Rails.cache.fetch('commits-v1', expires_in: 3.minutes) do
      commits.map do |c|
        {
          id:         c.id,
          name:       display_name(c),
          message:    c.message,
          insertions: c.insertions,
          deletions:  c.deletions
        }
      end
    end

    {
      commits: rendered
    }
  end
end
