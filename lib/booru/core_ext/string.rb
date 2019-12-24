# frozen_string_literal: true

class String
  # Generates a URL-safe slug from a string by removing nonessential
  # information from it.
  #
  # The process for this is as follows:
  #
  # 1. Remove non-ASCII or non-printable characters.
  #
  # 2. Replace any runs of non-alphanumeric characters that were allowed
  #    through previously with hyphens.
  #
  # 3. Remove any starting or ending hyphens.
  #
  # 4. Convert all characters to their lowercase equivalents.
  #
  # This method makes no guarantee of creating unique slugs for unique inputs.
  # In addition, for certain inputs, it will return empty strings. You can
  # handle this condition with a fallback on presence:
  #
  #   title.to_slug.presence || Time.zone.now.to_s.to_slug
  #
  # @return [String] a slug for this string
  # @example
  #   'Time-Wasting Thread 3.0 (SFW - No Explicit/Grimdark)'.to_slug
  #   #=> 'time-wasting-thread-3-0-sfw-no-explicit-grimdark'
  #
  #   '~`!@#$%^&*()-_=+[]{};:\'" <>,./?'.to_slug
  #   #=> ''
  #
  def to_slug
    gsub(/[^ -~]/, '')            # 1
      .gsub(/[^a-zA-Z0-9]+/, '-') # 2
      .gsub(/\A-|-\z/, '')        # 3
      .downcase                   # 4
  end
end
