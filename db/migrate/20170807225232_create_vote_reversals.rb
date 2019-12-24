class CreateVoteReversals < ActiveRecord::Migration[5.0]
  def change
    create_table :vote_reversals do |t|
      t.string :reason, null: false
      t.integer :user_id, null: false
      t.integer :image_ids, null: false, array: true, default: []
      t.timestamps
    end
  end
end
