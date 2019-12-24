# frozen_string_literal: true

class FingerprintProfilesController < ApplicationController
  def show
    authorize! :mod_read, User
    @fingerprint = params[:id]
    @user_fingerprints = UserFingerprint.where(fingerprint: @fingerprint).order(updated_at: :desc)
    @bans = FingerprintBan.where(fingerprint: @fingerprint)
    @title = "#{@fingerprint}'s fingerprint profile"
    respond_to do |format|
      format.html
      format.json { render json: { fingerprint: @fingerprint, user_fps: @user_fingeprints, bans: @bans } }
    end
  end
end
