class AddHideVoteCountsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :hide_vote_counts, :boolean, default: false
  end
end
