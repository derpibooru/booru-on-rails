# frozen_string_literal: true

require 'test_helper'

class CommissionTest < ActiveSupport::TestCase
  setup do
    @commission = build(:commission)
  end

  test 'should be valid' do
    assert @commission.valid?
  end

  test 'should be valid when an image is not given' do
    @commission.sheet_image_id = nil
    assert @commission.valid?
  end

  test 'should not be valid when a nonexistent image is given' do
    max_id = Image.all.maximum(:id) || 0
    @commission.sheet_image_id = max_id + 1
    assert_not @commission.valid?
  end

  test 'should not be valid when open is set to nil' do
    @commission.open = nil
    assert_not @commission.valid?
  end
end
