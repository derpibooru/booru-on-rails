# frozen_string_literal: true

class Posts::PreviewsController < ApplicationController
  skip_authorization_check only: [:create]

  def create
    @post = Post.new
    @post.user = current_user
    @post.anonymous = params[:anonymous] == true
    @post.body = params[:body].to_s
    render partial: 'communications/communication_preview', locals: { communication: @post }, layout: false
  end
end
