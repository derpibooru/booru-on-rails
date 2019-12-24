class AddCommissions < ActiveRecord::Migration[5.0]
  def change
    create_table :commissions do |t|
      t.references :user, foreign_key: true
      t.boolean :open, index: true
      t.string :categories, index: true, default: [], null: false, array: true
      t.string :information
      t.string :contact
      t.integer :sheet_image_id
      t.string :will_create
      t.string :will_not_create
      t.integer :commission_items_count, default: 0, null: false
      t.timestamps
    end

    create_table :commission_items do |t|
      t.references :commission, foreign_key: true
      t.string :item_type, index: true
      t.string :description
      t.decimal :base_price
      t.string :add_ons
      t.integer :example_image_id
      t.timestamps
    end
  end
end
