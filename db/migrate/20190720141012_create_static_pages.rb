class CreateStaticPages < ActiveRecord::Migration[6.0]
  def change
    create_table :static_pages do |t|
      t.timestamps

      t.text :title, null: false
      t.text :slug,  null: false
      t.text :body,  null: false

      t.index :slug,  unique: true
      t.index :title, unique: true
    end
  end
end
