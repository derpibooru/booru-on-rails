class NormalizeImpliedTags < ActiveRecord::Migration[5.2]
  def up
    create_table :tags_implied_tags, id: false do |t|
      t.belongs_to :tag,         null: false, index: false, type: :integer
      t.belongs_to :implied_tag, null: false, index: false, type: :integer
    end

    execute <<-SQL
      insert into tags_implied_tags (tag_id, implied_tag_id) select id as tag_id, unnest(implied_tag_ids) as implied_tag_id from tags group by tag_id, implied_tag_id;
      delete from tags_implied_tags where not exists (select null from tags where id=tags_implied_tags.implied_tag_id);
    SQL

    add_foreign_key :tags_implied_tags, :tags, on_delete: :cascade, on_update: :cascade
    add_foreign_key :tags_implied_tags, :tags, on_delete: :cascade, on_update: :cascade, column: :implied_tag_id

    add_index :tags_implied_tags, [:tag_id, :implied_tag_id], unique: true
    add_index :tags_implied_tags, :implied_tag_id
  end

  def down
    drop_table :tags_implied_tags
  end
end
