# frozen_string_literal: true

require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  setup do
    @comment = build(:comment)
  end

  test 'should be valid' do
    assert @comment.valid?
  end

  test 'should close open reports when hidden' do
    @comment.save!
    @report = create(:report, reportable: @comment)
    ReportableHider.new(@comment, reason: 'I just want to close the report.').save

    @report.reload
    assert_equal 'closed', @report.state
  end
end
