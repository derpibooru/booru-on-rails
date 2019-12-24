# frozen_string_literal: true

class SettingsController < ApplicationController
  skip_authorization_check

  def edit
    @title = 'Content Settings'
  end

  def update
    cookies['hidpi']     = { value: (params[:serve_hidpi] == '1'), expires: 25.years.from_now, httponly: false }
    cookies['webm']      = { value: (params[:webm] == '1'),        expires: 25.years.from_now, httponly: false }
    cookies['chan_nsfw'] = { value: (params[:chan_nsfw] == '1'),   expires: 25.years.from_now, httponly: false }

    if current_user.nil?
      redirect_to edit_settings_path, notice: 'Your settings have been saved!'
      return
    end

    current_user.clear_recent_filters! if params[:clear_recent_filters]

    cookies['hidestaff'] = { value: (params[:hide_staff_tools] == '1'), expires: 25.years.from_now, httponly: false } if current_user.role != 'user'

    if current_user.update(params.require(:user).permit(User::ALLOWED_PARAMETERS))
      redirect_to edit_settings_path, notice: 'Your settings have been saved!'
    else
      flash[:error] = 'Your settings could not be saved!'
      render action: 'edit'
    end
  end
end
