# frozen_string_literal: true

class ReportableHider < Hider
  def after_save
    # Also close any reports after hiding
    @component.close_open_reports!
  end
end
