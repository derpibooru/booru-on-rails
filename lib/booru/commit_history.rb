# frozen_string_literal: true

require 'simple_git'
require 'booru/commit_info'

module Booru
  # Provides an interface to walk through the commit history
  # of the application repository.
  class CommitHistory
    include Enumerable

    # Creates a new history walker.
    def initialize
      @repo = SimpleGit::Repository.new(Rails.root.to_s)
    end

    # @overload def each
    #   Creates an enumerator to the commit history.
    #   @return [Enumerable] An enumerator.
    #
    # @overload def each(&block)
    #   Walks the commit history, yielding a {CommitInfo}
    #   for each commit in turn.
    #   @return [Enumerable] An enumerator.
    #
    # @see CommitInfo
    def each
      # Nothing to call.
      return self unless block_given?

      walker = SimpleGit::Revwalk.new(@repo)
      walker.sort(:GIT_SORT_TOPOLOGICAL)
      walker.push_head

      walker.each do |c|
        # Commits with multiple parents are merge commits.
        #
        # Merge commits have multiple possible diffs, depending on which parent
        # tree is visited, and are mostly irrelevant to actual changes in the
        # state of the repository. They are ignored for the purposes of this
        # application.
        next if c.parent_count != 1

        ds = c.parent(0).diff(c).stats

        yield CommitInfo.new(
          id:         c.oid.to_s,
          time:       c.time,
          name:       c.author.name,
          email:      c.author.email,
          message:    c.message,
          insertions: ds.insertions,
          deletions:  ds.deletions
        )
      end

      self
    end
  end
end
