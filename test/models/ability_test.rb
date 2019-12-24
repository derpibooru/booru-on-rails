# frozen_string_literal: true

require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  setup do
    setup_test_users
  end

  test 'incompetent moderators can only manage user bans' do
    assert @moderator.can?(:manage, UserBan)
    assert @moderator.can?(:manage, SubnetBan)
    assert_not @moderator.can?(:manage, FingerprintBan)
  end

  test 'competent moderators can manage all types of bans' do
    @moderator.add_role :ban_competent
    assert @moderator.can?(:manage, UserBan)
    assert @moderator.can?(:manage, SubnetBan)
    assert @moderator.can?(:manage, FingerprintBan)
    @moderator.remove_role :ban_competent
  end
end
