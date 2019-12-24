# frozen_string_literal: true

require 'test_helper'

class UserBanTest < ActiveSupport::TestCase
  setup do
    @ban = build(:user_ban)
  end

  test 'should be valid' do
    assert @ban.valid?
  end

  test '.banned? should return the active ban when banned' do
    @ban.save
    assert_equal @ban, UserBan.banned?(@ban.user)
  end

  test '.banned? should return false when not banned' do
    assert_not UserBan.banned?(@ban.user) # did not save

    @ban = create(:expired_user_ban)
    assert_not UserBan.banned?(@ban.user)
  end
end
