class AddUserIpsUpdatedAtIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  def change
    add_index :user_ips, :updated_at, algorithm: :concurrently
  end
end
