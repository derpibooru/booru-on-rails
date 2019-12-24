class CreateStaticPageVersions < ActiveRecord::Migration[6.0]
  def change
    create_table :static_page_versions do |t|
      t.references :user,        null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }
      t.references :static_page, null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }
      t.timestamps

      t.text :title, null: false
      t.text :slug,  null: false
      t.text :body,  null: false
    end
  end
end
