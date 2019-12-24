# frozen_string_literal: true

require 'simple_git'

module Booru
  # A helper class for reading the current repository
  # version.
  class VersionReader
    # Get a new reference to the application repository.
    #
    # This is not memoized, so as to avoid holding a long-lived
    # reference to a repository object in the application.
    #
    # @return [SimpleGit::Repository]
    def self.repo
      SimpleGit::Repository.new(Rails.root.to_s)
    end

    # The current branch name as a string (e.g. "master").
    #
    # @return [String]
    def self.branch_name
      repo.head.branch_name
    rescue ArgumentError
      'unknown'
    end

    # The object id of the most recent commit as a string
    # (e.g. "3717f613f48df0222311f974cf8a06c8a6c97bae").
    #
    # @return [String]
    def self.head_commit
      repo.head.to_object.to_s
    rescue ArgumentError
      'unknown'
    end
  end

  VERSION        = '1.4.1'
  COMMIT         = VersionReader.head_commit[0..6]
  BRANCH         = VersionReader.branch_name

  VERSION_STRING = "#{VERSION}-#{COMMIT} (#{BRANCH})"
end
