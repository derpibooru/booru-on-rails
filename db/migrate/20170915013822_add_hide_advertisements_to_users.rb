class AddHideAdvertisementsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :hide_advertisements, :boolean, default: false
  end
end
