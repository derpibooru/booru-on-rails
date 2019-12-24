# frozen_string_literal: true

require 'test_helper'

class Conversations::HidesControllerTest < ActionController::TestCase
  setup do
    @conversation = create(:conversation_with_messages)
    @from = @conversation.from
    sign_in @from
  end

  test 'can hide a conversation' do
    post :create, params: { conversation_id: @conversation.slug }

    @conversation.reload
    assert_response :redirect
    assert @conversation.from_hidden
    assert_not @conversation.to_hidden
  end
end
