class AddPersonalTitleToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :personal_title, :string
  end
end
