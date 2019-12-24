class AddMissingIndices < ActiveRecord::Migration[5.1]
  def change
    change_column_null :user_fingerprints, :user_id, false
    change_column_null :user_ips, :user_id, false
    add_index :user_fingerprints, [:fingerprint, :user_id], unique: true
    add_index :user_ips, [:ip, :user_id], unique: true
  end
end
