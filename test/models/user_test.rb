# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = build(:user)
  end

  test 'should be valid' do
    @user.valid?
  end

  test 'should have default filter after creation' do
    @user.save!
    assert_equal 'Default', @user.current_filter.name
  end

  test 'switching filters should populate recent_filter_ids without duplicates' do
    @filter1 = create(:filter_everything)
    @filter2 = create(:filter_porn_only)

    assert_not_includes @user.recent_filter_ids, @filter1.id
    @user.set_filter!(@filter1)
    assert_includes @user.recent_filter_ids, @filter1.id

    @user.set_filter!(@filter2)
    @user.set_filter!(@filter1)
    @user.set_filter!(@filter2)
    assert_equal 1, @user.recent_filter_ids.count(@filter1.id)
    assert_equal 1, @user.recent_filter_ids.count(@filter2.id)
  end

  test '#staff?' do
    assert_not build(:user).staff?
    assert build(:assistant).staff?
    assert build(:moderator).staff?
    assert build(:admin).staff?
  end
end
