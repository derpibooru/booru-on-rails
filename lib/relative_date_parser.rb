# frozen_string_literal: true

module RelativeDateParser
  extend self

  def parse(str)
    str = str.squish
    return unless str =~ /\A(\d+) (second|minute|hour|day|week|month|year)s? ago\z/

    num = Regexp.last_match(1).to_i

    case Regexp.last_match(2)
    when 'second'
      higher = num.seconds.ago
      lower  = higher - 1.second
    when 'minute'
      higher = num.minutes.ago
      lower  = higher - 1.minute
    when 'hour'
      higher = num.hours.ago
      lower  = higher - 1.hour
    when 'day'
      higher = num.days.ago
      lower  = higher - 1.day
    when 'week'
      higher = num.weeks.ago
      lower  = higher - 1.week
    when 'month'
      higher = num.months.ago
      lower  = higher - 1.month
    when 'year'
      higher = num.years.ago
      lower  = higher - 1.year
    else
      return nil # can never get here
    end

    [higher, lower]
  end
end
