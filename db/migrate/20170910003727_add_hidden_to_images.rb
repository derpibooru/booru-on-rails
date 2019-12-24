class AddHiddenToImages < ActiveRecord::Migration[5.0]
  def change
    add_column :images, :hides, :integer, default: 0, null: false
  end
end
