# frozen_string_literal: true

require 'test_helper'

class Images::TagsControllerTest < ActionController::TestCase
  setup do
    @image = create(:image)
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should update tags' do
    @tag = create(:test_tag)

    assert_not @image.tags.to_a.include?(@tag)
    put :update, params: { image_id: @image.id, image: {
      tag_input:    "#{@image.tag_list}, #{@tag.name}",
      old_tag_list: @image.tag_list
    } }

    assert_response :success
    @image.reload
    assert @image.tags.to_a.include?(@tag)
    assert TagChange.exists? image: @image, tag: @tag, added: true

    put :update, params: { image_id: @image.id, image: {
      tag_input: (@image.tag_list.split(', ') - [@tag.name]).join(',')
    } }

    assert_response :success
    @image.reload
    assert_not @image.tags.to_a.include?(@tag)
    assert TagChange.exists? image: @image, tag: @tag, added: false
  end
end
