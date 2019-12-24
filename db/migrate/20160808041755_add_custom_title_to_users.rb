class AddCustomTitleToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :custom_title, :string
  end
end
