# frozen_string_literal: true

require 'test_helper'

class Filters::SpoilersControllerTest < ActionController::TestCase
  setup do
    @user_filter = create(:user_filter)
    @user_filter.user.set_filter! @user_filter
    sign_in @user_filter.user
  end

  test 'should spoiler/unspoiler' do
    @tag = create(:tag)

    post :create, params: { tagname: @tag.name }
    assert_redirected_to tag_path(@tag)
    assert @user_filter.reload.spoilered_tags.include?(@tag)

    delete :destroy, params: { tagname: @tag.name }
    assert_redirected_to tag_path(@tag)
    assert_not @user_filter.reload.spoilered_tags.include?(@tag)
  end
end
