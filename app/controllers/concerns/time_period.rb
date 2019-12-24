# frozen_string_literal: true

module TimePeriod
  LONG_FOR_SHORT_NAME = {
    'h' => 'hours',
    'd' => 'days',
    'w' => 'weeks'
  }.freeze

  def get_time_period
    last = params[:last] || '3d'
    short_timescale = last.match(/(\d+)([hdw])/)
    @time_period = if short_timescale
      short_timescale[1].to_i.send(LONG_FOR_SHORT_NAME[short_timescale[2]]).ago
    else
      3.days.ago
    end
  end
end
