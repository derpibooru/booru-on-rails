# frozen_string_literal: true

class Time
  def to_i_timestamp
    dup.to_i / 1.day
  end
end
