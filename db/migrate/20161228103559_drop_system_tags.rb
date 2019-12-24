class DropSystemTags < ActiveRecord::Migration[4.2]
  def change
    #remove_column :tags, :system

    Tag.rating_tags.update_all category: 'rating'
  end
end
