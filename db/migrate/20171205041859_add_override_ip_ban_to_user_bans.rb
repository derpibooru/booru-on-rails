class AddOverrideIpBanToUserBans < ActiveRecord::Migration[5.1]
  def change
    add_column :user_bans, :override_ip_ban, :boolean, default: false
  end
end
