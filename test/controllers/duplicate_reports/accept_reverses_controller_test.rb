# frozen_string_literal: true

require 'test_helper'

class DuplicateReports::AcceptReversesControllerTest < ActionController::TestCase
  test 'should accept in reverse' do
    sign_in create(:moderator)
    @duplicate_report = create(:duplicate_report)

    post :create, params: { duplicate_report_id: @duplicate_report }

    @duplicate_report.reload
    assert_response :redirect
    assert @duplicate_report.state == 'rejected'
    assert DuplicateReport.find_by(duplicate_of_image: @duplicate_report.image, image: @duplicate_report.duplicate_of_image).state == 'accepted'
  end
end
