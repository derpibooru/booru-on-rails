class RenameImgModNotesToScratchpad < ActiveRecord::Migration[4.2]
  def change
    rename_column :images, :mod_notes, :scratchpad
  end
end
