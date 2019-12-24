class CreateImageFeatures < ActiveRecord::Migration[6.0]
  def change
    create_table :image_features do |t|
      t.references :image, null: false, foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }

      t.timestamps

      t.index :created_at
    end
  end
end
