class AddTopicPollSupport < ActiveRecord::Migration[5.1]
  def change
    create_table :polls, id: :integer do |t|
      t.string :title, limit: 140, null: false
      t.string :vote_method, limit: 8, null: false
      t.timestamp :active_until, null: false
      t.integer :total_votes, default: 0, null: false
      t.timestamps
      t.boolean :hidden_from_users, default: false, null: false
      t.integer :deleted_by_id, null: true
      t.string :deletion_reason, default: '', null: false
      t.belongs_to :topic, index: true, foreign_key: { on_delete: :cascade, on_update: :cascade }, type: :integer, null: false
    end

    create_table :poll_options, id: :integer do |t|
      t.string :label, limit: 80, null: false
      t.integer :vote_count, default: 0, null: false
      t.belongs_to :poll, index: true, foreign_key: { on_delete: :cascade, on_update: :cascade }, type: :integer, null: false
      t.index [:poll_id, :label], unique: true
    end

    create_table :poll_votes, id: :integer do |t|
      t.integer :rank, null: true
      t.belongs_to :poll_option, foreign_key: { on_delete: :cascade, on_update: :cascade }, type: :integer, null: false
      t.belongs_to :user, foreign_key: { on_delete: :cascade, on_update: :cascade }, type: :integer, null: false
      t.datetime :created_at, null: false
      t.index [:poll_option_id, :user_id], unique: true
    end
  end
end
