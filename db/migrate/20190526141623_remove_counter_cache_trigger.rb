class RemoveCounterCacheTrigger < ActiveRecord::Migration[5.2]
  def change
    execute <<-SQL
      DROP TRIGGER update_unread_notifications_count ON unread_notifications CASCADE;
      DROP FUNCTION increment_counter;
      DROP FUNCTION counter_cache;
    SQL

    remove_column :users, :unread_notification_count
  end
end
