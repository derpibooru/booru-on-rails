class AddSessionsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :sessions, id: :serial do |t|
      t.string :session_id, null: false, index: { unique: true }
      t.text :data
      t.datetime :created_at, null: false, default: -> { 'now()' }
      t.datetime :updated_at, null: false, index: true, default: -> { 'now()' }
    end
  end
end
