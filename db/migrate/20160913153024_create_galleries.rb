class CreateGalleries < ActiveRecord::Migration[4.2]
  def change
    create_table :galleries do |t|
      t.string :title,           null: false
      t.string :spoiler_warning, null: false, default: ''
      t.string :description,     null: false, default: ''
      t.references :thumbnail
      t.references :creator
      t.timestamps               null: false
    end

    create_table :gallery_interactions do |t|
      t.integer :position,       null: false, index: true
      t.references :image,       null: false, index: true, foreign_key: true
      t.references :gallery,     null: false, index: true, foreign_key: true
    end

    Image.__elasticsearch__.client.indices.put_mapping index: 'images', type: 'image',
                                                       body: Image.__elasticsearch__.mapping.to_hash
  end
end
