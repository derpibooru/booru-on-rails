class DropUserInteractions < ActiveRecord::Migration[6.0]
  def change
    drop_table :user_interactions
  end
end
