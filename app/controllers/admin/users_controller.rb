# frozen_string_literal: true

class Admin::UsersController < ApplicationController
  before_action :check_auth, except: [:index]
  before_action :load_user, except: [:index]

  def index
    authorize! :mod_read, User

    @users = if params[:q]
      @query = params[:q]
      User.where('(name ILIKE ?) OR (email = ?)', @query + '%', @query)
    else
      User
    end.order(created_at: :desc)

    @title = 'Admin - Users'
    @users = @users.where(role: User::STAFF_ROLES) if params[:staff].present?
    @users = @users.where(otp_required_for_login: true) if params[:twofactor].present? && can?(:twofactor, User)
    @users = @users.page(params[:page]).per(50)

    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def edit
    @title = "Editing User: #{@user.name}"
  end

  def update
    if @current_user.can?(:manage, Role)
      @user.set_or_unset_role params[:batch_tag],            :batch_update, Tag
      @user.set_or_unset_role params[:abuses_polls],         :abuses,       Poll
      @user.set_or_unset_role params[:abuses_poll_votes],    :abuses,       PollVote
      @user.set_or_unset_role params[:image_mod] == '1',     :moderator,    Image
      @user.set_or_unset_role params[:dupe_mod] == '1',      :moderator,    DuplicateReport
      @user.set_or_unset_role params[:comment_mod] == '1',   :moderator,    Comment
      @user.set_or_unset_role params[:tag_mod] == '1',       :moderator,    Tag
      @user.set_or_unset_role params[:link_mod] == '1',      :moderator,    UserLink
      @user.set_or_unset_role params[:user_edit] == '1',     :moderator,    User
      @user.set_or_unset_role params[:forum_mod] == '1',     :moderator,    Topic
      @user.set_or_unset_role params[:tag_admin] == '1',     :admin,        Tag
      @user.set_or_unset_role params[:can_notice] == '1',    :admin,        SiteNotice
      @user.set_or_unset_role params[:can_badges] == '1',    :admin,        Badge
      @user.set_or_unset_role params[:can_roles] == '1',     :admin,        Role
      @user.set_or_unset_role params[:can_advert] == '1',    :admin,        Advert
      @user.set_or_unset_role params[:flipper] == '1',       :flipper
      @user.set_or_unset_role params[:ban_competent] == '1', :ban_competent
      @user.set_or_unset_role params[:twofactor] == '1',     :twofactor
    end

    authorize! :manage, Role if (role_changed = params[:user][:role].present? && @user.role != params[:user][:role])

    respond_to do |format|
      if @user.update(user_params)
        if role_changed
          @user.unsubscribe_restricted_actors
          modfeed_push_role_change @user.role, params[:user][:role]
        else
          modfeed_push 'Edited'
        end
        format.html { redirect_to profile_path(@user.slug), notice: 'User was successfully updated.' }
        format.json { render json: @user, status: :created, location: admin_users_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def check_auth
    authorize! :manage, User
  end

  def load_user
    @user = User.find_by_slug_or_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @user
  end

  def modfeed_push(status)
    UserLogger.log(status, @user, current_user)
  end

  def modfeed_push_role_change(old_role, new_role)
    UserLogger.log_role(old_role, new_role, @user, current_user)
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :secondary_role, :hide_default_role, :personal_title, :uploaded_avatar, :hide_advertisements, :remove_avatar)
  end
end
