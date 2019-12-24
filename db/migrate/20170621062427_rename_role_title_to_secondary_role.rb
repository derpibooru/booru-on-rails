class RenameRoleTitleToSecondaryRole < ActiveRecord::Migration[5.0]
  def change
    rename_column :users, :role_title, :secondary_role
  end
end
