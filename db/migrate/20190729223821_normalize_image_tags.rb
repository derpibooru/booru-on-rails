class NormalizeImageTags < ActiveRecord::Migration[6.0]
  def change
    create_table :image_taggings, id: false do |t|
      t.bigint :image_id, null: false
      t.bigint :tag_id, null: false
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
          insert into image_taggings (image_id, tag_id)
          select id, tag_id from images, unnest(images.tag_ids) as tag_id
          where exists (select 1 from tags where tags.id = tag_id)
          group by id, tag_id;
        SQL
      end

      dir.down do
      end
    end

    add_index :image_taggings, [:image_id, :tag_id], unique: true
    add_index :image_taggings, :tag_id

    add_foreign_key :image_taggings, :images, on_update: :cascade, on_delete: :cascade
    add_foreign_key :image_taggings, :tags, on_update: :cascade, on_delete: :cascade
  end
end
