# frozen_string_literal: true

require 'test_helper'

class CommissionItemTest < ActiveSupport::TestCase
  setup do
    @commission_item = build(:commission_item)
  end

  test 'should be valid' do
    assert @commission_item.valid?
  end
end
