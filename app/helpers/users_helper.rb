# frozen_string_literal: true

module UsersHelper
  def sparkline_data(data)
    max = [data.max, 0].max
    min = [data.min, 0].max

    content_tag :svg, width: '100%', preserveAspectRatio: 'none', viewBox: '0 0 90 20' do
      data.each_with_index do |val, i|
        # Filter out negative values.
        calc = [val, 0].max

        # Simple linear interpolation, or 0 if none present.
        height = (calc - min) * 20.0 / (max - min)
        height = 0 if height.nan?
        height = height.to_i

        # In SVG coordinates, y grows down.
        y = 20 - height

        concat content_tag(:rect, content_tag(:title, val), class: 'barline__bar', x: i, y: y, width: 1, height: height)
      end
    end
  end
end
