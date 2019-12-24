# frozen_string_literal: true

require 'ban_finder'
require 'dnsbl'

module UserFilter
  def current_ban
    if !defined?(@current_ban)
      @current_ban = BanFinder.finds_ban_for?(request, current_user, cookies, true)
      @current_ban = nil if filter_ip_dnsbl
    end

    @current_ban
  end

  def require_user
    if current_user.nil?
      flash[:error] = t('booru.errors.account_required')
      respond_to do |format|
        format.html { redirect_to new_user_session_path }
        format.json { render json: { message: flash[:error] }, status: :forbidden }
        format.js { head :forbidden }
      end
    end
  end

  def filter_banned_users
    error = filter_ip_dnsbl
    error ||= filter_account_lock
    error ||= filter_current_ban
    error ||= filter_missing_fingerprint
    return unless error

    flash[:alert] = error
    respond_to do |format|
      format.html { redirect_back }
      format.json { render json: { message: error }, status: :forbidden }
      format.js { head :forbidden }
    end
  end

  private

  def filter_ip_dnsbl
    ip_high_risk = DNSBL.high_risk?(request.remote_ip, current_user)
    t('booru.errors.ip_high_risk', reason: ip_high_risk) if ip_high_risk
  end

  def filter_account_lock
    account_locked = $flipper[:new_account_lock].enabled?
    account_locked &&= (!current_user || (current_user && (Time.zone.now - current_user.created_at < 2.days)))
    account_locked ||= !$flipper[:site_interactivity].enabled?
    t('booru.errors.site_locked') if account_locked
  end

  def filter_current_ban
    return unless current_ban

    details = { until: @current_ban.valid_until.to_s(:db), reason: @current_ban.reason, ban_id: @current_ban.generated_ban_id }
    t('booru.errors.user_banned', details)
  end

  def filter_missing_fingerprint
    fp_valid = FingerprintBan.valid_fingerprint?(cookies['_ses']) || request.format.json?
    t('booru.errors.missing_fingerprint') unless fp_valid
  end
end
