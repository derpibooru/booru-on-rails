# frozen_string_literal: true

class Stats::ChartsController < ApplicationController
  skip_authorization_check

  content_security_policy do |policy|
    policy.frame_ancestors :self
    policy.script_src      :unsafe_inline, 'https://www.amcharts.com'
    policy.style_src       :unsafe_inline
    policy.img_src         'https://www.amcharts.com'
  end

  def show
    @images_aggregation = Image.search(Booru::CONFIG.aggregation[:images])

    respond_to do |format|
      format.html { render layout: false }
    end
  end
end
