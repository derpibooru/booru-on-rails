# frozen_string_literal: true

module Booru
  # Helper class for CommitHistory.
  class CommitInfo
    # The specific git object ID associated with this commit
    # as a string (e.g. "3717f613f48df0222311f974cf8a06c8a6c97bae").
    #
    # @return [String]
    attr_reader :id

    # The time this commit was made.
    #
    # @return [Time]
    attr_reader :time

    # The name of the author of this commit
    # as a string (e.g. "Linus Torvalds").
    #
    # @return [String]
    attr_reader :name

    # The email address of the author of this commit
    # as a string (e.g. "torvalds@linuxfoundation.org").
    #
    # @return [String]
    attr_reader :email

    # The full commit message for this commit, including
    # any trailing newlines.
    #
    # @return [String]
    attr_reader :message

    # The number of insertions in a line-based diff for this commit.
    # The diff base is the tree of the first parent commit.
    #
    # @return [Integer]
    attr_reader :insertions

    # The number of deletions in a line-based diff for this commit.
    # The diff base is the tree of the first parent commit.
    #
    # @return [Integer]
    attr_reader :deletions

    # Create a new CommitInfo object with the specified parameters.
    def initialize(id:, time:, name:, email:, message:, insertions:, deletions:)
      @id         = id
      @time       = time
      @name       = name
      @email      = email
      @message    = message
      @insertions = insertions
      @deletions  = deletions
    end
  end
end
