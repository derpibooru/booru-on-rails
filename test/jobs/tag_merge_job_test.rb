# frozen_string_literal: true

require 'test_helper'
require 'image_loader'

class TagMergeJobTest < ActiveJob::TestCase
  setup do
    queue_adapter.perform_enqueued_jobs = true
    create(:safe)
    reset_state
  end

  test 'alias sets corresponding attributes' do
    TagMergeJob.perform_now @source.id, @target.id, true
    @source = @source.reload

    assert Tag.exists? id: @source.id
    assert_equal @target.id, @source.aliased_tag_id
  end

  test 'hard merge destroys the tag' do
    TagMergeJob.perform_now @source.id, @target.id, false

    assert_not Tag.exists? id: @source.id
  end

  test 'alias and hard merge move images' do
    [true, false].each do |create_alias|
      reset_state
      TagMergeJob.perform_now @source.id, @target.id, create_alias
      @target.reload

      assert_equal 0, @source.images.count
      assert_equal @images.size, @target.images.count
      assert_equal @images.size, @target.images_count

      refresh_index Image
      if create_alias
        assert_equal @images.size, ImageLoader.new.search(@source.name).total_count
      else
        assert_equal 0, ImageLoader.new.search(@source.name).total_count
      end
      assert_equal @images.size, ImageLoader.new.search(@target.name).results.total_count
    end
  end

  def reset_state
    @source, @target = create_list :tag, 2
    @supplementary_tags = Tag.make_tags_from_names(['safe']) + create_list(:tag, Booru::CONFIG.settings[:tags][:min_count] - 2)
    @images = create_list :image_skips_validation, 4
    @images.each do |i|
      i.add_tags [@source] + @supplementary_tags
      i.save!
    end
    @source.reload
    assert_equal @images.size, @source.images_count
  end
end
