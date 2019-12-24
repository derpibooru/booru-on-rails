class CreateUserNameChanges < ActiveRecord::Migration[5.1]
  def self.up
    create_table :user_name_changes, id: :serial do |t|
      t.references :user, foreign_key: true
      t.string :name
      t.timestamps
    end

    add_column :users, :last_renamed_at, :datetime, default: Time.at(0), null: false
    add_column :comments, :name_at_post_time, :string
    add_column :posts, :name_at_post_time, :string

    Comment.where.not(user_id: nil).where(name_at_post_time: nil).includes(:user).all.find_each{|c| c.update_columns(name_at_post_time: c.user&.name)}
    Post.where.not(user_id: nil).where(name_at_post_time: nil).includes(:user).all.find_each{|p| p.update_columns(name_at_post_time: p.user&.name)}
  end

  def self.down
    drop_table :user_name_changes
    remove_column :posts, :name_at_post_time, :string
    remove_column :comments, :name_at_post_time, :string
    remove_column :users, :last_renamed_at, :datetime
  end
end
