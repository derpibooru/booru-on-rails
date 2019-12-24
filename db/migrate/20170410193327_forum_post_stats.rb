class ForumPostStats < ActiveRecord::Migration[5.0]
  def change
    add_column :user_statistics, :forum_posts, :integer, default: 0, null: false
    rename_column :users, :post_count, :forum_posts_count
  end
end
