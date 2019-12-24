# frozen_string_literal: true

require 'test_helper'

class UserLinkTest < ActiveSupport::TestCase
  setup do
    @user_link = create(:user_link)
  end

  test 'should transition state properly' do
    assert_equal 'unverified', @user_link.aasm_state

    @user_link.mark_link_verified!
    assert_equal 'link_verified', @user_link.aasm_state

    @user_link.mark_contacted!
    assert_equal 'contacted', @user_link.aasm_state

    @user_link.reject!
    assert_equal 'rejected', @user_link.aasm_state

    @user_link.mark_verified!
    assert_equal 'verified', @user_link.aasm_state
  end
end
