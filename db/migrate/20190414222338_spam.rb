class Spam < ActiveRecord::Migration[5.1]
  def change
    remove_column :comments, :potential_spam
    remove_column :posts, :potential_spam
    remove_column :users, :spam_count
  end
end
