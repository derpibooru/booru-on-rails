# frozen_string_literal: true

module Reportable
  extend ActiveSupport::Concern

  included do
    has_many :reports, validate: false, as: :reportable, dependent: :delete_all
  end

  def close_open_reports!
    reports.where(open: true).find_each do |r|
      r.open = false
      r.state = 'closed'
      r.save!
      r.update_index
      ReportLogger.log(r, 'Closed')
    end
  end
end
