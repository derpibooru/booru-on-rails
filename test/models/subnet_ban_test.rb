# frozen_string_literal: true

require 'test_helper'

class SubnetBanTest < ActiveSupport::TestCase
  setup do
    @ban = build(:subnet_ban)
  end

  test 'should be valid' do
    assert @ban.valid?
  end

  test '.banned? should return the active ban when banned' do
    @ban.save
    assert_equal @ban, SubnetBan.banned?(@ban.specification)
  end

  test '.banned? should return false when not banned' do
    assert_not SubnetBan.banned?(@ban.specification) # did not save

    @ban = create(:expired_subnet_ban)
    assert_not SubnetBan.banned?(@ban.specification)
  end
end
