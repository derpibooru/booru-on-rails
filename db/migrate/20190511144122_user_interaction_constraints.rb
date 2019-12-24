class UserInteractionConstraints < ActiveRecord::Migration[5.2]
  def change
    change_column_null :user_interactions, :user_id, false
    change_column_null :user_interactions, :image_id, false
  end
end
