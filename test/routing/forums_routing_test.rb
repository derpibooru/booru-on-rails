# frozen_string_literal: true

require 'test_helper'

class ForumRoutesTest < ActionDispatch::IntegrationTest
  test 'routes /forums to the forums index' do
    assert_routing '/forums', controller: 'forums', action: 'index'
  end

  test 'routes /forums/short_name and /short_name to the forums show page' do
    f = create(:forum)
    assert_routing "/forums/#{f.to_param}", controller: 'forums', action: 'show', id: f.to_param
    assert_recognizes({ controller: 'forums', action: 'show', id: f.to_param }, "/#{f.to_param}")
  end

  test "routes /[forums/]:forum/topics/:topic to the topic's first page" do
    t = create(:topic)
    assert_routing "/forums/#{t.forum.to_param}/topics/#{t.to_param}", controller: 'topics', action: 'show', id: t.to_param, forum_id: t.forum.to_param
    assert_recognizes({ controller: 'topics', action: 'show', id: t.to_param, forum_id: t.forum.to_param }, "/#{t.forum.to_param}/topics/#{t.to_param}")
  end

  test "routes /[forums/]:forum/:topic to the topic's first page" do
    t = create(:topic)
    assert_recognizes({ controller: 'topics', action: 'show', id: t.to_param, forum_id: t.forum.to_param }, "/forums/#{t.forum.to_param}/#{t.to_param}")
    assert_recognizes({ controller: 'topics', action: 'show', id: t.to_param, forum_id: t.forum.to_param }, "/#{t.forum.to_param}/#{t.to_param}")
  end
end
