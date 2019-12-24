# frozen_string_literal: true

class PostHider < ReportableHider
  def after_save
    super
    @component.clean_up_after_deletion!
  end
end
