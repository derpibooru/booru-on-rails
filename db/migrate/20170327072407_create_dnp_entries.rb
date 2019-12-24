class CreateDnpEntries < ActiveRecord::Migration[5.0]
  def change
    create_table :dnp_entries do |t|
      t.references :requesting_user, foreign_key: { to_table: :users }, null: false
      t.references :modifier, foreign_key: { to_table: :users }
      t.references :tag, foreign_key: true, null: false
      t.string :aasm_state, default: "requested", null: false
      t.string :dnp_type, null: false
      t.string :conditions
      t.string :reason
      t.boolean :hide_reason, default: false
      t.string :instructions
      t.string :feedback
      t.timestamps
    end
  end
end
