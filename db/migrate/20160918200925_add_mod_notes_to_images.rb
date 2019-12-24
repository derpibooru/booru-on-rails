class AddModNotesToImages < ActiveRecord::Migration[4.2]
  def change
    add_column :images, :mod_notes, :string
  end
end
