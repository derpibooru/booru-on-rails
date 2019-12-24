# frozen_string_literal: true

class UserWipeJob < ApplicationJob
  queue_as :low
  WIPE_IP = '127.0.1.1'
  WIPE_FP = 'ffff'

  def perform(id)
    user = User.find(id)
    Comment.where(user_id: user.id).find_each do |c|
      c.update_columns(ip: WIPE_IP, fingerprint: WIPE_FP)
    end
    Image.where(user_id: user.id).find_each do |i|
      i.update_columns(ip: WIPE_IP, fingerprint: WIPE_FP)
    end
    Post.where(user_id: user.id).find_each do |p|
      p.update_columns(ip: WIPE_IP, fingerprint: WIPE_FP)
    end
    Report.where(user_id: user.id).find_each do |r|
      r.update_columns(ip: WIPE_IP, fingerprint: WIPE_FP)
    end
    SourceChange.where(user_id: user.id).find_each do |sc|
      sc.update_columns(ip: WIPE_IP, fingerprint: WIPE_FP)
    end
    TagChange.where(user_id: user.id).find_each do |tc|
      tc.update_columns(ip: WIPE_IP, fingerprint: WIPE_FP)
    end
    UserIp.where(user_id: user.id).delete_all
    UserFingerprint.where(user_id: user.id).delete_all
    user.update_columns(email: "deactivated#{Digest::MD5.hexdigest(user.email)}@example.com", current_sign_in_ip: WIPE_IP, last_sign_in_ip: WIPE_IP)
  end
end
