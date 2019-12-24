class RemoveSessionsTable < ActiveRecord::Migration[5.1]
  def up
    drop_table :sessions
  end
end
