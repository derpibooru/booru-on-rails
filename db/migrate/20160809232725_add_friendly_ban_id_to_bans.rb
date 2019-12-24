class AddFriendlyBanIdToBans < ActiveRecord::Migration[4.2]
  def change
    add_column :user_bans, :generated_ban_id, :string
    add_column :subnet_bans, :generated_ban_id, :string
    add_column :fingerprint_bans, :generated_ban_id, :string
  end
end
