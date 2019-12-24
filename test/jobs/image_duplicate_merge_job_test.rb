# frozen_string_literal: true

require 'test_helper'

class ImageDuplicateMergeJobTest < ActiveJob::TestCase
  setup do
    queue_adapter.perform_enqueued_jobs = true
    reset_state
  end

  test 'should hide images after merging' do
    setup_test_users

    ImageDuplicateMergeJob.perform_now @source.id, @target.id, nil
    [@source, @target].each(&:reload)

    assert_equal @source.duplicate_id, @target.id
    assert @source.hidden_from_users

    [@user, @comment_assistant, @tag_assistant].each { |u| assert_not @source.visible_to? u }
    [@dupe_assistant, @image_assistant, @admin].each { |u| assert @source.visible_to? u }
  end

  test 'should set the earliest first_seen_at on the target' do
    ImageDuplicateMergeJob.perform_now @source.id, @target.id, nil
    [@source, @target].each(&:reload)

    assert_equal @target.first_seen_at, @earliest_first_seen_at

    reset_state

    ImageDuplicateMergeJob.perform_now @target.id, @source.id, nil
    [@source, @target].each(&:reload)

    assert_equal @source.first_seen_at, @earliest_first_seen_at
  end

  test 'should add tags from source to target' do
    @source_tags = create_list(:tag, 2) + [Tag.find_by(name: 'safe')]
    @source.add_tags @source_tags
    @source.save!

    ImageDuplicateMergeJob.perform_now @source.id, @target.id, nil
    [@source, @target].each(&:reload)

    assert((@source_tags - @target.tags).empty?)
    tag_list = Tag.parse_tag_list(@target.tag_list)
    (@source_tags + @target.tags).uniq.map(&:name).each { |tag| assert_includes tag_list, tag }
  end

  test 'should copy notification subscriptions' do
    setup_test_users

    Notification.watch @source, @user
    Notification.watch @target, @admin

    ImageDuplicateMergeJob.perform_now @source.id, @target.id, nil
    [@source, @target].each(&:reload)

    assert Notification.watching? @target, @user
    assert Notification.watching? @target, @admin
  end

  test 'should move comments' do
    @comments = create_list :comment, 2, image: @source

    ImageDuplicateMergeJob.perform_now @source.id, @target.id, nil
    [@source, @target].each(&:reload)

    assert @source.comments.empty?
    assert((@comments - @target.comments).empty?)
  end

  test 'should move image interactions' do
    @user = create :user

    @source.votes.create(user: @user, up: true)
    @source.faves.create(user: @user)

    ImageDuplicateMergeJob.perform_now @source.id, @target.id, nil
    [@source, @target].each(&:reload)

    assert @target.votes.where(user: @user).exists?
    assert @target.faves.where(user: @user).exists?
  end

  test 'should update galleries' do
    @galleries = create_list :gallery, 2
    @galleries.each { |g| g.add @source }

    ImageDuplicateMergeJob.perform_now @source.id, @target.id, nil
    [@source, @target].each(&:reload)

    assert @source.gallery_interactions.empty?
    assert_equal @galleries.map(&:id), @target.gallery_interactions.map(&:gallery_id)
  end

  test 'should not create duplicate gallery entries' do
    @galleries = create_list :gallery, 2
    @galleries.each { |g| g.add @source }
    @galleries.first.add @target

    ImageDuplicateMergeJob.perform_now @source.id, @target.id, nil
    [@source, @target, @galleries].flatten.each(&:reload)

    assert_equal @galleries.map(&:id), @target.gallery_interactions.map(&:gallery_id)
    assert_equal [1, 1], @galleries.map(&:image_count)
  end

  def reset_state
    @earliest_first_seen_at = Time.zone.local(2000, 1, 1)
    @source = create :image_skips_validation, created_at: Time.zone.local(2000, 1, 1), first_seen_at: @earliest_first_seen_at
    @target = create :image_skips_validation, created_at: Time.zone.local(2010, 1, 1), first_seen_at: Time.zone.local(2010, 1, 1)
  end
end
