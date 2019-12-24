class CreateImageIntensities < ActiveRecord::Migration[6.0]
  def change
    create_table :image_intensities do |t|
      t.references :image, null: false, foreign_key: true, index: false
      t.float :nw, null: false
      t.float :ne, null: false
      t.float :sw, null: false
      t.float :se, null: false

      t.index :image_id, unique: true
    end
  end
end
