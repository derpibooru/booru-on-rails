class RenameModNotesUserToModerator < ActiveRecord::Migration[5.0]
  def change
    rename_column :mod_notes, :user_id, :moderator_id
  end
end
