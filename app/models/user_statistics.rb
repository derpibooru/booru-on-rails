# frozen_string_literal: true

class UserStatistics < ApplicationRecord
  belongs_to :user, inverse_of: :statistics, optional: true

  def self.trim_old_stats_models
    UserStatistics.where('day < ?', 91.days.ago.to_i_timestamp).delete_all
  end
end
