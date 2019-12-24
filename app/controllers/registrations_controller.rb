# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  before_action :filter_banned_users

  def create
    if current_ban
      respond_to do |format|
        format.html { redirect_to '/', alert: "Sorry, you've been banned from using the site until #{@current_ban.valid_until.to_s(:db)}. Reason given: #{@current_ban.reason}. If you feel this has been done in error, contact an administrator." }
        format.js { head :ok }
      end
      return false
    end
    if verify_captcha
      super
    else
      build_resource
      clean_up_passwords(resource)
      flash[:alert] = "There was an error verifying you're human. Please redo the checks and submit."
      render :new
    end
  end

  def edit
    if resource.otp_secret.blank?
      resource.generate_otp_secret!
      resource.save!
    end
    super
  end

  def update
    if !resource.valid_password?(params[:user][:current_password])
      redirect_back flash: { error: 'Invalid password.' }
      return
    end

    if params[:user][:name].present? && resource.name != params[:user][:name]
      if resource.recently_renamed?
        redirect_back flash: { error: 'You have changed your name too recently.' }
        return
      end

      begin
        User.transaction do
          existing_name = resource.name
          resource.name = params[:user][:name]
          resource.last_renamed_at = Time.zone.now
          resource.save!
          resource.name_changes.new(name: existing_name).save!
        end
      rescue StandardError
        redirect_back flash: { error: 'New name already in use.' }
        return
      end
    end

    if params[:enable_twofactor_otp].present?
      otp = params[:enable_twofactor_otp].presence
      if !current_user.validate_and_consume_otp!(otp)
        redirect_back flash: { error: "Two factor authentication code doesn't match" }
        return
      end

      current_user.otp_required_for_login = true
      flash[:otp_backup_codes] = current_user.generate_otp_backup_codes!
      current_user.save!
    elsif params[:disable_twofactor_otp].present?
      otp_or_backup_code = params[:disable_twofactor_otp].presence
      if !current_user.validate_and_consume_otp!(otp_or_backup_code)
        if !current_user.invalidate_otp_backup_code!(otp_or_backup_code)
          redirect_back flash: { error: "Two factor authentication code or backup code doesn't match" }
          return
        end
      end

      current_user.otp_required_for_login = false
      # Re-generate codes to invalidate the old ones
      current_user.generate_otp_secret!
      current_user.generate_otp_backup_codes!
      current_user.save!
    end

    super
  end

  def after_update_path_for(resource)
    return edit_user_registration_path if flash[:otp_backup_codes]

    profile_path(resource.slug)
  end
end
