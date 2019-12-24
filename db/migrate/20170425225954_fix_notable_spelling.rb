class FixNotableSpelling < ActiveRecord::Migration[5.0]
  def change
    rename_column :mod_notes, :noteable_id, :notable_id
    rename_column :mod_notes, :noteable_type, :notable_type
  end
end
