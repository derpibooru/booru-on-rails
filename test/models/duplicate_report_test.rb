# frozen_string_literal: true

require 'test_helper'

class DuplicateReportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    queue_adapter.perform_enqueued_jobs = true
    @image = create(:dedupe_image_1)
    @image2 = create(:dedupe_image_2)
    [@image, @image2].each(&:reload)
    @report = DuplicateReport.create image: @image, duplicate_of_image: @image2, reason: 'Test'
    @user = create(:user)
  end

  test 'should not submit a report for invalid arguments' do
    refute_validity = ->(attributes) { assert_not DuplicateReport.new(attributes).valid? }

    refute_validity.call(image: @image, duplicate_of_image: @image, reason: 'Test')
    refute_validity.call(image_id: 9_000, duplicate_of_image: @image, reason: 'Test')
    refute_validity.call(image: @image, duplicate_of_image_id: 9_000, reason: 'Test')
  end

  test 'can accept a report' do
    queue_adapter.perform_enqueued_jobs = false
    assert_enqueued_with(job: ImageDuplicateMergeJob, args: [@image.id, @image2.id, @user.id]) do
      assert @report.accept!(@user)
    end
    assert_equal 'accepted', @report.state
  end

  test 'can reject a report' do
    @report.reject!(@user)

    assert_nil @image.duplicate_id
    assert_not @image.hidden_from_users
    assert_equal @user, @report.modifier
    assert_equal 'rejected', @report.state
  end

  test 'rejecting a report should undo accepting it' do
    assert @report.accept!(@user)
    [@image, @image2].each(&:reload)
    assert @image.hidden_from_users
    assert_equal @image2.id, @image.duplicate_id

    assert @report.reject!(@user)
    assert_not @image.hidden_from_users
    assert_nil @image.duplicate_id
  end

  test 'should detect duplicates' do
    assert @image.detect_duplicates(0.25, 0.25).to_a.include? @image2

    @dupes = [create(:dupe_1), create(:dupe_2)]
    assert DuplicateReport.exists? image: @dupes
  end
end
