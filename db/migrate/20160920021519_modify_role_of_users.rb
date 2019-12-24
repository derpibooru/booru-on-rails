class ModifyRoleOfUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :custom_title
    add_column :users, :hide_default_role, :boolean, default: :false
  end
end
