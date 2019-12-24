# frozen_string_literal: true

require 'test_helper'

class AnonyHashTest < ActiveSupport::TestCase
  include AnonyHash

  def setup_anon_comments
    @comment_by_anon_1 = build(:comment)
    @other_comment_by_anon_1 = build(:comment, image: @comment_by_anon_1.image)
    @comment_by_anon_2 = build(:comment, image: @comment_by_anon_1.image, ip: '127.0.0.2', fingerprint: 'b644f06bec4d7bf01148affa374bf5291')
  end

  test 'comments by the same anon should have the same hash' do
    setup_anon_comments
    assert_equal get_anony_hash(@comment_by_anon_1), get_anony_hash(@other_comment_by_anon_1)
  end

  test 'comments by different anons should have different hashes' do
    setup_anon_comments
    assert_not_equal get_anony_hash(@comment_by_anon_1), get_anony_hash(@comment_by_anon_2)
  end

  def setup_anon_tag_changes
    @tag_change_by_anon_1 = build(:tag_change)
    @other_tag_change_by_anon_1 = build(:tag_change, image: @tag_change_by_anon_1.image)
    @tag_change_by_anon_2 = build(:tag_change, image: @tag_change_by_anon_1.image, ip: '127.0.0.2', fingerprint: 'b644f06bec4d7bf01148affa374bf5291')
  end

  test 'tag changes by the same anon should have the same hash' do
    setup_anon_tag_changes
    assert_equal get_anony_hash(@tag_change_by_anon_1), get_anony_hash(@other_tag_change_by_anon_1)
  end

  test 'tag changes by different anons should have the same hash' do
    setup_anon_tag_changes
    assert_not_equal get_anony_hash(@tag_change_by_anon_1), get_anony_hash(@tag_change_by_anon_2)
  end

  def setup_anon_source_changes
    @source_change_by_anon_1 = build(:source_change)
    @other_source_change_by_anon_1 = build(:source_change, image: @source_change_by_anon_1.image)
    @source_change_by_anon_2 = build(:source_change, image: @source_change_by_anon_1.image, ip: '127.0.0.2', fingerprint: 'b644f06bec4d7bf01148affa374bf5291')
  end

  test 'source changes by the same anon should have the same hash' do
    setup_anon_source_changes
    assert_equal get_anony_hash(@source_change_by_anon_1), get_anony_hash(@other_source_change_by_anon_1)
  end

  test 'source changes by different anons should have the same hash' do
    setup_anon_source_changes
    assert_not_equal get_anony_hash(@source_change_by_anon_1), get_anony_hash(@source_change_by_anon_2)
  end

  def setup_anon_posts
    topic = build(:topic)
    @post_by_anon_1 = build(:post, topic: topic)
    @other_post_by_anon_1 = build(:post, topic: topic)
    @post_by_anon_2 = build(:post, topic: topic, ip: '127.0.0.2', fingerprint: 'b644f06bec4d7bf01148affa374bf5291')
  end

  test 'posts by the same anon should have the same hash' do
    setup_anon_posts
    assert_equal get_anony_hash(@post_by_anon_1), get_anony_hash(@other_post_by_anon_1)
  end

  test 'posts by different anons should have different hashes' do
    setup_anon_posts
    assert_not_equal get_anony_hash(@post_by_anon_1), get_anony_hash(@post_by_anon_2)
  end
end
