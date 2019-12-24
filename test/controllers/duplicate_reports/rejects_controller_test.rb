# frozen_string_literal: true

require 'test_helper'

class DuplicateReports::RejectsControllerTest < ActionController::TestCase
  test 'should reject' do
    sign_in create(:moderator)
    @duplicate_report = create(:duplicate_report)

    post :create, params: { duplicate_report_id: @duplicate_report }

    @duplicate_report.reload
    assert_response :redirect
    assert @duplicate_report.state == 'rejected'
  end
end
