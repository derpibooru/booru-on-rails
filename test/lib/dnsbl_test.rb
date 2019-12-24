# frozen_string_literal: true

require 'test_helper'
require 'dnsbl'

class DNSBLTest < ActiveSupport::TestCase
  ip = '127.0.0.2'

  test 'low-risk addresses should not see anything' do
    assert_not DNSBL.high_risk?('3.3.3.3')
  end

  # FIXME: this test never worked
  #test 'high-risk addresses should be told to contact an administrator' do
    #assert_includes DNSBL.high_risk?(ip), "you're connecting from a high-risk IP address"
  #end

  test 'Tor users should be considered high risk' do
    assert_includes DNSBL.high_risk?('127.0.0.1'), 'Welcome, Tor hidden service user'
  end

  test 'registered users should not be considered high-risk' do
    assert_not DNSBL.high_risk?(ip, build(:user))
  end
end
