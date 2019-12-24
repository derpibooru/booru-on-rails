class CreateModNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :mod_notes do |t|
      t.references :user, index: true, foreign_key: true
      t.references :noteable, polymorphic: true, index: true
      t.text :body
      t.boolean :deleted, default: false

      t.timestamps null: false
    end
  end
end
