# frozen_string_literal: true

class Admin::UserLinks::TransitionsController < ApplicationController
  before_action :check_auth
  before_action :load_link

  def create
    @link.verified_by_user = current_user
    if params[:do] == 'mark_verified'
      if @link.mark_verified!
        modfeed_push('verified')
        redirect_back notice: 'User Link successfully verified.'
      else
        render action: 'new'
      end
    elsif params[:do] == 'mark_contacted'
      @link.contacted_at = Time.zone.now
      @link.contacted_by_user = current_user
      if @link.mark_contacted!
        modfeed_push('contacted')
        redirect_back notice: 'User Link successfully marked as contacted.'
      else
        render action: 'new'
      end
    elsif params[:do] == 'reject'
      if @link.reject!
        modfeed_push('rejected')
        redirect_back notice: 'User Link successfully rejected.'
      else
        render action: 'new'
      end
    end
  end

  private

  def check_auth
    authorize! :manage, UserLink
  end

  def load_link
    @link = UserLink.find(params[:user_link_id])
  end

  def modfeed_push(status)
    UserLinkLogger.log(status, @link.user, current_user)
  end
end
