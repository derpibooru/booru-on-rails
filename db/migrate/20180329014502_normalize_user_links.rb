class NormalizeUserLinks < ActiveRecord::Migration[5.1]
  def up
    execute <<~SQL
      create table user_links_2 as select * from user_links;
      truncate user_links;
      alter table user_links drop column tag_ids;
      alter table user_links add column tag_id integer;


      -- cardinality(tag_ids) > 0
      insert into user_links (
        aasm_state, uri, hostname, path, verification_code, public,
        tag_id,
        next_check_at, contacted_at, created_at,
        updated_at, user_id, verified_by_user_id, contacted_by_user_id
      )
      select
        aasm_state, uri, hostname, path, verification_code, public,
        unnest(tag_ids) as tag_id,
        next_check_at, contacted_at, created_at,
        updated_at, user_id, verified_by_user_id, contacted_by_user_id 
      from user_links_2 where cardinality(tag_ids) > 0;


      -- cardinality(tag_ids) = 0
      insert into user_links (
        aasm_state, uri, hostname, path, verification_code, public,
        tag_id,
        next_check_at, contacted_at, created_at,
        updated_at, user_id, verified_by_user_id, contacted_by_user_id
      )
      select
        aasm_state, uri, hostname, path, verification_code, public,
        NULL::int as tag_id,
        next_check_at, contacted_at, created_at,
        updated_at, user_id, verified_by_user_id, contacted_by_user_id 
      from user_links_2 where cardinality(tag_ids) = 0;
    SQL

    add_index :user_links, :tag_id
  end


  def down
    execute <<~SQL
      drop table user_links;
      alter table user_links_2 rename to user_links;
    SQL
  end
end
