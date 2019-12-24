class NormalizeInteractions < ActiveRecord::Migration[6.0]
  def change
    create_table :image_faves, id: false do |t|
      t.belongs_to :image, null: false, index: false, foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.belongs_to :user, null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }
      t.timestamp :created_at, null: false

      t.index [:image_id, :user_id], unique: true
    end

    create_table :image_hides, id: false do |t|
      t.belongs_to :image, null: false, index: false, foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.belongs_to :user, null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }
      t.timestamp :created_at, null: false

      t.index [:image_id, :user_id], unique: true
    end

    create_table :image_votes, id: false do |t|
      t.belongs_to :image, null: false, index: false, foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.belongs_to :user, null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }
      t.timestamp :created_at, null: false
      t.boolean :up, null: false

      t.index [:image_id, :user_id], unique: true
    end

    change_table :images do |t|
      t.rename :upvotes, :upvotes_count
      t.rename :downvotes, :downvotes_count
      t.rename :votes, :votes_count
      t.rename :favourites, :faves_count
      t.rename :hides, :hides_count
    end
  end
end
