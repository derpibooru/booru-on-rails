# frozen_string_literal: true

module Enumerable
  # Returns duplicate elements from +self+.
  #
  # If a block is given, it will use the return value of the
  # given block for comparison.
  #
  # @return [Array<Array>]
  # @example
  #   [1, 2, 3].non_uniq
  #   #=> []
  #
  #   [1, 1, 2, 3].non_uniq
  #   #=> [[1, 1]]
  #
  #   [1, 1, 1, 2, 3].non_uniq
  #   #=> [[1, 1, 1]]
  #
  #   [1, 2, 3, 4].non_uniq { |x| x * 0 }
  #   #=> [[1, 2, 3, 4]]
  #
  def non_uniq(&block)
    block ||= proc { |item| item }
    group_by(&block).select { |_, occurrences| occurrences.count > 1 }.values
  end
end
