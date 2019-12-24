# frozen_string_literal: true

require 'test_helper'
require 'ban_finder'

class BanFinderTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:remote_ip)

  test '.finds_ban_for? for a subnet ban should work' do
    @ban = create(:subnet_ban)
    @request = FakeRequest.new(@ban.specification)
    assert BanFinder.finds_ban_for?(@request, nil, nil)
  end

  test '.finds_ban_for? for a fingerprint ban should work' do
    @ban = create(:fingerprint_ban)
    @request = FakeRequest.new('::')
    assert BanFinder.finds_ban_for?(@request, nil, '_ses' => @ban.fingerprint)
  end

  test '.finds_ban_for? for a user ban should work' do
    @ban = create(:user_ban)
    @request = FakeRequest.new('::')
    assert BanFinder.finds_ban_for?(@request, @ban.user)
  end
end
