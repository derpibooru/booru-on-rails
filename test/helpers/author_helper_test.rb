# frozen_string_literal: true

require 'test_helper'

class AuthorHelperTest < ActionView::TestCase
  include AuthorHelper

  test 'author should show anon posts as Background Pony' do
    @post = create(:post)
    assert_match /\ABackground Pony #\h{4}\z/, @post.author
    assert_match /\ABackground Pony #\h{4}\z/, link_to_author(@post, false)
    assert_match /\ABackground Pony #\h{4}\z/, link_to_author(@post, true)
  end

  test 'author should show as-anon posts as Background Pony' do
    @post = create(:post_as_anon)
    assert_match /\ABackground Pony #\h{4}\z/, @post.author
    assert_match /\ABackground Pony #\h{4}\z/, link_to_author(@post, false)
    assert_match @post.user.name, link_to_author(@post, true)
  end

  test 'author should show normal posts as their user name' do
    @post = create(:post_as_user)
    assert_equal @post.user.name, @post.author
    assert_match @post.user.name, link_to_author(@post, false)
    assert_match @post.user.name, link_to_author(@post, true)
  end
end
