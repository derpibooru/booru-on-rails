class AddModNotesToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :mod_notes, :string
  end
end
