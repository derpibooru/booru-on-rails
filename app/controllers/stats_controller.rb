# frozen_string_literal: true

class StatsController < ApplicationController
  skip_authorization_check

  content_security_policy do |policy|
    policy.frame_src :self
  end

  def show
    @title = 'Site Statistics'
    @images_aggregation = Image.search(Booru::CONFIG.aggregation[:images])
    @comments_aggregation = Comment.search(Booru::CONFIG.aggregation[:comments])
  end
end
