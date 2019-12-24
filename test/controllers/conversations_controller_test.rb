# frozen_string_literal: true

require 'test_helper'

class ConversationsControllerTest < ActionController::TestCase
  setup do
    @request.cookies['_ses'] = 'c1836832948'
    @conversation = create(:conversation_with_messages)
    @from = @conversation.from
    sign_in @from
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:conversations)
  end

  test 'should get show' do
    get :show, params: { id: @conversation }
    assert_response :success
    assert_equal @conversation, assigns(:conversation)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'can create conversation' do
    @to = @conversation.to

    assert_difference(['Conversation.count', 'Message.count']) do
      post :create, params: { conversation: { recipient: @to.name, title: 'New conversation', messages_attributes: [body: 'Hello'] } }
      assert_response :redirect
    end
  end
end
