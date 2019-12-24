class RenameModifierToModifyingUser < ActiveRecord::Migration[5.0]
  def change
    rename_column :dnp_entries, :modifier_id, :modifying_user_id
  end
end
