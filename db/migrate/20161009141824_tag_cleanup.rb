class TagCleanup < ActiveRecord::Migration[4.2]
  def change
    remove_column :tags, :hidden
    remove_column :tags, :spoiler
    remove_column :tags, :subspoiler
    remove_column :tags, :implied_by_tag_ids
  end
end
