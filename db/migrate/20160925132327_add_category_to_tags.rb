class AddCategoryToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :category, :string
  end
end
