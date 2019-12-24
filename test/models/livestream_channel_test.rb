# frozen_string_literal: true

require 'test_helper'

class LivestreamChannelTest < ActiveSupport::TestCase
  setup do
    @channel = build(:livestream_channel)
  end

  test 'should be valid' do
    assert @channel.valid?
  end

  test '.api_name should escape channel names' do
    assert_equal 'xspittfireartx', LivestreamChannel.api_hostname('spittfireart')
    assert_equal 'xspittfire-artx', LivestreamChannel.api_hostname('spittfire_art')
  end

  test '.api_root should return an API URL' do
    assert_equal 'http://xspittfireartx.api.channel.livestream.com/2.0', LivestreamChannel.api_root('spittfireart')
  end

  test '.find_short_name should sanitize its input properly' do
    assert_equal 'spittfireart', LivestreamChannel.find_short_name('http://www.livestream.com/spittfireart')
    assert_equal 'spittfireart', LivestreamChannel.find_short_name('http://www.livestream.com/spittfireart?blasdasf=asd')
    assert_equal 'spittfireart', LivestreamChannel.find_short_name('http://www.livestream.com/spittfireart/some-videos')
    assert_equal 'spittfireart', LivestreamChannel.find_short_name('http://www.livestream.com/spittfireart/some-other-videos?blasdasf=asd')
    assert_equal 'spittfireart', LivestreamChannel.find_short_name('http://livestream.com/spittfireart/some-other-videos?blasdasf=asd')
    assert_not LivestreamChannel.find_short_name('http://www.ustream.com')
  end

  test '#fetch should parse the response correctly' do
    @channel.short_name = 'spittfireart' # something we know that has some hits
    VCR.use_cassette('livestream-fetch') do
      @channel.fetch
      assert_not_nil @channel.title
      assert_not_nil @channel.description
      assert @channel.viewers > 0
      assert @channel.viewer_minutes_today > 0
      assert @channel.viewer_minutes_thisweek > 0
      assert @channel.viewer_minutes_thismonth > 0
      assert @channel.total_viewer_minutes > 0
      assert_not_nil @channel.tags
    end
  end
end
