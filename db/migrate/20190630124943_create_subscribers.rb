class CreateSubscribers < ActiveRecord::Migration[6.0]
  def change
    create_table :channel_subscriptions, id: false do |t|
      t.integer :channel_id, null: false
      t.integer :user_id, null: false
    end

    create_table :forum_subscriptions, id: false do |t|
      t.integer :forum_id, null: false
      t.integer :user_id, null: false
    end

    create_table :gallery_subscriptions, id: false do |t|
      t.integer :gallery_id, null: false
      t.integer :user_id, null: false
    end

    create_table :image_subscriptions, id: false do |t|
      t.integer :image_id, null: false
      t.integer :user_id, null: false
    end

    create_table :topic_subscriptions, id: false do |t|
      t.integer :topic_id, null: false
      t.integer :user_id, null: false
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
          insert into channel_subscriptions (channel_id, user_id)
          select id, sub_id from channels, unnest(channels.watcher_ids) as sub_id
          where exists (select 1 from users where users.id=sub_id) group by id, sub_id;

          insert into forum_subscriptions (forum_id, user_id)
          select id, sub_id from forums, unnest(forums.watcher_ids) as sub_id
          where exists (select 1 from users where users.id=sub_id) group by id, sub_id;

          insert into gallery_subscriptions (gallery_id, user_id)
          select id, sub_id from galleries, unnest(galleries.watcher_ids) as sub_id
          where exists (select 1 from users where users.id=sub_id) group by id, sub_id;

          insert into image_subscriptions (image_id, user_id)
          select id, sub_id from images, unnest(images.watcher_ids) as sub_id
          where exists (select 1 from users where users.id=sub_id) group by id, sub_id;

          insert into topic_subscriptions (topic_id, user_id)
          select id, sub_id from topics, unnest(topics.watcher_ids) as sub_id
          where exists (select 1 from users where users.id=sub_id) group by id, sub_id;
        SQL
      end

      dir.down do
      end
    end

    add_index :channel_subscriptions, [:channel_id, :user_id], unique: true
    add_index :forum_subscriptions, [:forum_id, :user_id], unique: true
    add_index :gallery_subscriptions, [:gallery_id, :user_id], unique: true
    add_index :image_subscriptions, [:image_id, :user_id], unique: true
    add_index :topic_subscriptions, [:topic_id, :user_id], unique: true

    add_index :channel_subscriptions, :user_id
    add_index :forum_subscriptions, :user_id
    add_index :gallery_subscriptions, :user_id
    add_index :image_subscriptions, :user_id
    add_index :topic_subscriptions, :user_id

    add_foreign_key :channel_subscriptions, :channels, on_delete: :cascade, on_update: :cascade
    add_foreign_key :forum_subscriptions, :forums, on_delete: :cascade, on_update: :cascade
    add_foreign_key :gallery_subscriptions, :galleries, on_delete: :cascade, on_update: :cascade
    add_foreign_key :image_subscriptions, :images, on_delete: :cascade, on_update: :cascade
    add_foreign_key :topic_subscriptions, :topics, on_delete: :cascade, on_update: :cascade

    add_foreign_key :channel_subscriptions, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :forum_subscriptions, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :gallery_subscriptions, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :image_subscriptions, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :topic_subscriptions, :users, on_delete: :cascade, on_update: :cascade
  end
end
