# frozen_string_literal: true

require 'test_helper'

class BulkIndexUpdateJobTest < ActiveJob::TestCase
  test 'should not fail when the requested records do not exist' do
    assert_nothing_raised do
      perform_enqueued_jobs { BulkIndexUpdateJob.perform_now 'Tag', [0o12017] }
    end
  end
end
