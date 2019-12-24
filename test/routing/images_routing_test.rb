# frozen_string_literal: true

require 'test_helper'

class ImagesRoutesTest < ActionDispatch::IntegrationTest
  test 'routes /images and / to the images index' do
    assert_routing '/images', controller: 'images', action: 'index'
  end

  test 'routes /images/:id and /:id to the images show page' do
    i = create(:image)
    assert_routing "/images/#{i.to_param}", controller: 'images', action: 'show', id: i.to_param
    assert_recognizes({ controller: 'images', action: 'show', id: i.to_param }, "/#{i.to_param}")
  end
end
