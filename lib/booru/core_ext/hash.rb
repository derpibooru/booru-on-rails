# frozen_string_literal: true

class Hash
  # Switches keys and values.
  #
  # Unlike {#invert}, the method preserves duplicate entries, storing them in
  # an array. It does not overwrite them with the last.
  #
  # @return [Hash]
  # @example
  #   {1 => 2}.invert
  #   #=> {2 => 1}
  #
  #   {1 => 2}.full_invert
  #   #=> {2 => [1]}
  #
  #   {1 => 10, 2 => 10, 3 => 10, 4 => 20, 5 => 20}.invert
  #   #=> {10 => 3, 20 => 5}
  #
  #   {1 => 10, 2 => 10, 3 => 10, 4 => 20, 5 => 20}.full_invert
  #   #=> {10 => [1, 2, 3], 20 => [4, 5]}
  #
  def full_invert
    each_with_object({}) do |(k, v), obj|
      (obj[v] ||= []) << k
    end
  end
end
