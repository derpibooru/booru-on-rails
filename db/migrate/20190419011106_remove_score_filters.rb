class RemoveScoreFilters < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :max_score
    remove_column :users, :min_score
  end
end
