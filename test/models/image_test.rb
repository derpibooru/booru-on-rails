# frozen_string_literal: true

require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  setup do
    @image = create(:image)
  end

  test 'should be valid' do
    assert @image.valid?
  end

  test 'should raise a validation error on exact dupes' do
    @image.save!
    assert @image.valid?

    @image2 = build(:image)
    assert_not @image2.valid?
  end

  test 'should set first_seen_at to created_at' do
    @image.save!
    assert_equal @image.created_at, @image.first_seen_at
  end

  def setup_tags
    @safe = Tag.find_tag_by_name('safe')
    @tags = create_list :tag, Booru::CONFIG.settings[:tags][:min_count]
  end

  test 'tag addition should be validated' do
    setup_tags

    @image.add_tags @tags + [@safe]
    assert @image.save

    assert_includes @image.tag_list, @tags.first.name
    assert_includes @image.tags.to_a, @safe

    @image.remove_tags [@safe]
    assert_not @image.save
    @image.remove_tags [@tags.first]
    assert @image.save

    assert_not_includes @image.tag_list, @tags.first.name
    assert_not_includes @image.tags.to_a, @tags.first
  end

  test '#hide! should prevent users from seeing things' do
    setup_test_users

    @image.save!
    assert_not @image.hidden_from_users
    assert @image.visible_to?(@user)
    assert @image.visible_to?(@dupe_assistant)
    assert @image.visible_to?(@image_assistant)
    assert @image.visible_to?(@comment_assistant)
    assert @image.visible_to?(@tag_assistant)
    assert @image.visible_to?(@admin)

    ImageHider.new(@image, reason: 'The age of deletion is upon us.').save
    assert @image.hidden_from_users
    assert_not @image.visible_to?(@user)
    assert_not @image.visible_to?(@dupe_assistant)
    assert @image.visible_to?(@image_assistant)
    assert_not @image.visible_to?(@comment_assistant)
    assert_not @image.visible_to?(@tag_assistant)
    assert @image.visible_to?(@admin)

    ImageUnhider.new(@image).save
    assert_not @image.hidden_from_users
    assert @image.visible_to?(@user)
    assert @image.visible_to?(@dupe_assistant)
    assert @image.visible_to?(@image_assistant)
    assert @image.visible_to?(@comment_assistant)
    assert @image.visible_to?(@tag_assistant)
    assert @image.visible_to?(@admin)
  end

  def hide_and_destroy_image_content
    @image.save!
    ImageHider.new(@image, reason: 'Because they felt like it.').save
    ImageDestroyer.new(@image).save
  end

  test '#destroy_content! should set maintain model validity.' do
    hide_and_destroy_image_content

    assert @image.valid?
  end

  test '#destroy_content! should update attributes appropriately.' do
    hide_and_destroy_image_content

    @image.reload
    assert @image.read_attribute(:image).nil?
    assert @image.destroyed_content
  end

  test 'destroying a hidden record should not decrement tag counters' do
    @image.save!
    tag = @image.tags.first
    assert_difference(-> { tag.reload.images_count }, -1) { ImageHider.new(@image, reason: 'Just because.').save }
    assert_difference(-> { tag.reload.images_count }, 0) { ImageDestroyer.new(@image).save }
  end
end
