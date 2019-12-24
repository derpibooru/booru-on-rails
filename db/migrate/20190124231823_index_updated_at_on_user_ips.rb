class IndexUpdatedAtOnUserIps < ActiveRecord::Migration[5.1]
  def change
    execute "create index index_user_ips_on_user_id_and_updated_at on user_ips (user_id, updated_at desc);"
  end
end
