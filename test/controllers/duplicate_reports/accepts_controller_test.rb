# frozen_string_literal: true

require 'test_helper'

class DuplicateReports::AcceptsControllerTest < ActionController::TestCase
  test 'should accept' do
    sign_in create(:moderator)
    @duplicate_report = create(:duplicate_report)

    post :create, params: { duplicate_report_id: @duplicate_report }

    @duplicate_report.reload
    assert_response :redirect
    assert @duplicate_report.state == 'accepted'
  end
end
