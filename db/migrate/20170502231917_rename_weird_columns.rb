class RenameWeirdColumns < ActiveRecord::Migration[5.0]
  def change
    rename_column :images, :up_vote_count, :upvotes
    rename_column :images, :down_vote_count, :downvotes
    rename_column :images, :vote_count, :votes
  end
end
