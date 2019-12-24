class DropDnpEntries < ActiveRecord::Migration[5.0]
  def change
    drop_table :dnp_entries
  end
end
