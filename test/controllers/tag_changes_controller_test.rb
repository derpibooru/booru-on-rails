# frozen_string_literal: true

require 'test_helper'

class TagChangesControllerTest < ActionController::TestCase
  setup do
    @image = create(:image)
    @tags = create_list(:tag, 2)
    @user = create(:moderator)
    @request.cookies['_ses'] = 'c1836832948'
    sign_in @user
  end

  test 'tag changes should be revertible' do
    setup_tag_changes

    patch :mass_revert, params: { ids: [@addition.id, @removal.id] }

    @image.reload
    assert_not_includes @image.tag_list, @addition.tag.name
    assert_includes @image.tag_list, @removal.tag.name
    assert TagChange.where(user: @user, image: @image, tag: @addition.tag, added: false).exists?
    assert TagChange.where(user: @user, image: @image, tag: @removal.tag, added: true).exists?
  end

  test 'tag changes for non-existent tags should be irreversible' do
    setup_tag_changes
    @removal.tag.delete

    patch :mass_revert, params: { ids: [@removal.id] }

    @image.reload
    assert_not_includes @image.tag_list, @removal.tag.name
    assert_not TagChange.where(user: @user, image: @image, tag: @removal.tag, added: true).exists?
  end

  def setup_tag_changes
    @image.add_tags @tags
    @image.save
    @image.remove_tags [@tags.last]
    @image.save

    assert_includes @image.tag_list, @tags.first.name
    assert_not_includes @image.tag_list, @tags.last.name

    @addition = TagChange.create! ip: '203.0.113.0', fingerprint: 'c1836832948',
                                  user: @user, image: @image, tag: @tags.first, added: true

    @removal = TagChange.create! ip: '203.0.113.0', fingerprint: 'c1836832948',
                                 user: @user, image: @image, tag: @tags.last, added: false
  end
end
