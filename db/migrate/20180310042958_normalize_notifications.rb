class NormalizeNotifications < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    create_table :unread_notifications, id: :serial do |t|
      t.references :notification, type: :integer, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.references :user,         type: :integer, foreign_key: { on_delete: :cascade }, index: true, null: false
    end

    add_index :unread_notifications, [:notification_id, :user_id], unique: true
    add_column :users, :unread_notification_count, :integer, default: 0, null: false

    # backfill and install trigger
    execute <<-SQL
      insert into unread_notifications (notification_id, user_id)
        select unnest(unread_notification_ids) as notification_id, id as user_id from users where cardinality(unread_notification_ids) > 0
        on conflict do nothing;
      create trigger update_unread_notifications_count
        after insert or update or delete on unread_notifications
        for each row execute procedure counter_cache('users', 'unread_notification_count', 'user_id');
    SQL
  end

  def down
    execute <<-SQL
      drop trigger update_unread_notifications_count on unread_notifications;
      alter table users drop column unread_notification_count;
      drop table unread_notifications;
    SQL
  end
end
