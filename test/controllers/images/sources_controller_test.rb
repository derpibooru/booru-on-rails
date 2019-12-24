# frozen_string_literal: true

require 'test_helper'

class Images::SourcesControllerTest < ActionController::TestCase
  setup do
    @image = create(:image)
    @request.cookies['_ses'] = 'c1836832948'
  end

  test 'should update source' do
    @new_source = 'https://source.me'

    assert @image.source_url != @new_source
    put :update, params: { image_id: @image.id, image: {
      source_url: @new_source
    } }

    assert_response :success
    @image.reload
    assert @image.source_url == @new_source
  end
end
