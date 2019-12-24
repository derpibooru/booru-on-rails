# frozen_string_literal: true

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @tag = create(:tag)
  end

  test 'should normalize tag names on creation' do
    Tag.create(name: 'EenAhp')
    assert_not Tag.where(name: 'EenAhp').exists?
    assert Tag.where(name: 'eenahp').exists?
  end

  test 'should normalize tag names before uniqueness validation' do
    Tag.create(name: 'EenAhp')
    assert_raises(ActiveRecord::RecordInvalid) { Tag.create!(name: 'eenahp') }
  end

  def make_image_and_tag
    @image = create(:dedupe_image_1)
    @image.add_tags [@tag]
    @image.save
  end

  test 'images_count should change when tagged' do
    assert_difference('@tag.images_count') do
      make_image_and_tag
      [@image, @tag].each(&:reload)
    end

    # Prevent tag suiciding.
    @image2 = create(:dedupe_image_2)
    @image2.add_tags [@tag]
    @image2.save
    [@image2, @tag].each(&:reload)
    assert_difference('@tag.images_count', -1) do
      @image.remove_tags [@tag]
      @image.save
      [@image, @tag].each(&:reload)
    end
  end

  test 'aliasing should be revertible' do
    @tag.target_tag_name = create(:tag).name
    @tag.save

    @tag.target_tag_name = ''
    assert @tag.save
    assert_nil @tag.aliased_tag
    assert_nil @tag.aliased_tag_name
  end
end
