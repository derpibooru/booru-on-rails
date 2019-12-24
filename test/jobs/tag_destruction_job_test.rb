# frozen_string_literal: true

require 'test_helper'

class TagDestructionJobTest < ActiveJob::TestCase
  test 'should validate tag destruction' do
    rating_tag = create(:safe)
    refute_destruction rating_tag
    (alias_target = create(:tag)) && Tag.create!(name: 'aliased tag', aliased_tag_id: alias_target.id)
    refute_destruction alias_target
    (implied_tag = create(:tag)) && Tag.create!(name: 'implied by', implied_tag_ids: [implied_tag.id])
    refute_destruction implied_tag
    (spoilered_tag = create(:tag)) && Filter.create!(system: true, name: 'spoilers', description: '', spoilered_tag_ids: [spoilered_tag.id])
    refute_destruction spoilered_tag
    (hidden_tag = create(:tag)) && Filter.create!(system: true, name: 'hides', description: '', hidden_tag_ids: [hidden_tag.id])
    refute_destruction hidden_tag
    spoiler_tag = Tag.create!(name: 'spoiler:spoiler tag')
    refute_destruction spoiler_tag
  end

  test 'should enqueue destruction job for validated tags' do
    tag = create(:tag)
    assert_enqueued_with(job: TagDestructionJob, args: [tag.id]) do
      assert tag.destroy
    end
  end

  def refute_destruction(tag)
    assert_not tag.destroy
    assert_not_empty tag.errors
    assert_enqueued_jobs 0
  end

  test 'should clean up associations' do
    tag = create(:tag)
    alias_target = create(:tag)
    tag.aliased_tag = alias_target
    tag.save

    assert_enqueued_with(job: ReindexTagJob, args: [tag.aliased_tag_id]) do
      TagDestructionJob.perform_now(tag.id)
    end
  end

  test 'should remove tag from filters and watchlists' do
    tag = create(:tag)
    fake_id = (tag.id + 1)

    spoiler_filter = Filter.create!(name: 'spoilers', description: '', spoilered_tag_ids: [tag.id, fake_id])
    hide_filter = Filter.create!(name: 'hides', description: '', hidden_tag_ids: [tag.id, fake_id])
    (tag_watcher = create(:user)) && tag_watcher.update_column(:watched_tag_ids, [tag.id, fake_id])

    perform_enqueued_jobs { tag.destroy }

    assert_equal [fake_id], spoiler_filter.reload.spoilered_tag_ids
    assert_equal [fake_id], hide_filter.reload.hidden_tag_ids
    assert_equal [fake_id], tag_watcher.reload.watched_tag_ids
  end

  test 'should remove tag from images' do
    tag = create(:tag)
    image = create(:image)
    image_old_tag_ids = image.tag_ids.dup

    image.ip = '127.0.0.1'
    image.tags.push tag
    image.save
    comment = Comment.create! image: image, body: 'comment', ip: '127.0.0.1'

    assert_enqueued_with(job: BulkIndexUpdateJob, args: ['Comment', [comment.id]]) do
      assert_enqueued_with(job: BulkIndexUpdateJob, args: ['Image', [image.id]]) do
        TagDestructionJob.perform_now(tag.id)
      end
    end

    assert_equal image_old_tag_ids, image.reload.tag_ids
  end
end
