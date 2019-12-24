class UserLinkTagUriUserUnique < ActiveRecord::Migration[5.1]
  def up
    execute <<~SQL
      delete from user_links
        where aasm_state <> 'rejected'
        and id not in(
          select min(id)
          from user_links
          group by uri, tag_id, user_id
        );

      create unique index index_user_links_on_uri_tag_id_user_id
        on user_links (uri, tag_id, user_id)
        where aasm_state <> 'rejected';
    SQL
  end
end
