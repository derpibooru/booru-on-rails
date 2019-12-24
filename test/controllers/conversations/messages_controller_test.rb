# frozen_string_literal: true

require 'test_helper'

class Conversations::MessagesControllerTest < ActionController::TestCase
  setup do
    @request.cookies['_ses'] = 'c1836832948'
    @conversation = create(:conversation_with_messages)
    @from = @conversation.from
    sign_in @from
  end

  test 'should get new' do
    get :new, params: { conversation_id: @conversation.slug }
    assert_response :success
  end

  test 'can post a reply to an existing conversation' do
    assert_difference('Message.count') do
      post :create, params: { conversation_id: @conversation.slug, message: { body: 'How are you?' } }
      assert_response :redirect
    end
  end
end
