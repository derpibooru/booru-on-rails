# frozen_string_literal: true

require 'test_helper'

class Admin::Batch::TagsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:moderator)
    @user.add_role :batch_update, Tag
    sign_in @user

    @tags = create_list(:tag, 2)
  end

  test 'should batch add tags' do
    @images = create_list(:image_skips_validation, 4)

    assert_enqueued_with(job: BulkIndexUpdateJob, args: ['Image', @images.map(&:id)]) do
      put :update, params: { tags: @tags.map(&:name).join(','), image_ids: @images.map(&:id) }
      assert_response :success
      assert_equal @images.map(&:id), json_response['succeeded']
    end

    @images.map(&:reload).each do |image|
      @tags.each do |tag|
        assert_includes image.tags.to_a, tag
        assert TagChange.exists? image: image, tag: tag, user: @user, added: true
      end
    end
  end

  test 'should not create tag changes for tags that are already present' do
    @image = create(:image_skips_validation)
    @image.add_tags [@tags.first]
    @image.save

    put :update, params: { tags: @tags.map(&:name).join(','), image_ids: [@image.id] }
    assert_response :success

    assert_not TagChange.exists? image: @image, tag: @tags.shift
    @tags.each { |tag| assert TagChange.exists? image: @image, tag: tag }
  end

  def json_response
    ActiveSupport::JSON.decode @response.body
  end
end
