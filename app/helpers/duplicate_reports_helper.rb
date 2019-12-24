# frozen_string_literal: true

module DuplicateReportsHelper
  def comparison_url(image)
    image.image.url 'full', hidden: can?(:undelete, Image) && image.hidden_from_users?
  end

  def largest_dimensions(*args)
    args.map { |i| [i.image_width, i.image_height] }.max_by { |w, h| w * h }
  end
end
