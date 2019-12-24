class AddPerUserLayoutSwitch < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :use_centered_layout, :boolean, default: false
  end
end
