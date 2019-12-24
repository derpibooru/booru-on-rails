class RenameModNotesToScratchpad < ActiveRecord::Migration[4.2]
  def change
  	rename_column :users, :mod_notes, :scratchpad
  	change_column :users, :scratchpad, :text
  end
end
