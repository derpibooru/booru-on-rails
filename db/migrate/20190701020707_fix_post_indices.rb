class FixPostIndices < ActiveRecord::Migration[6.0]
  def change
    remove_index :posts, [:topic_id, :created_at, :topic_position]
    add_index :posts, [:topic_id, :created_at]
    add_index :posts, [:topic_id, :topic_position]
  end
end
