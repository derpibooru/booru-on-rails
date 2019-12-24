class FixDatabase < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        Post.where(topic_position: nil).find_each do |p|
          p.update_columns(topic_position: p.topic.posts.order('topic_position desc nulls last').first.topic_position || 0)
        end

        execute <<-SQL
          -- fix known ref integrity violations
          update channels set associated_artist_tag_id = null where not exists (select null from tags where tags.id=channels.associated_artist_tag_id);
          update commissions set sheet_image_id = null where not exists (select null from images where images.id=commissions.sheet_image_id);
          update images set duplicate_id = null where images.duplicate_id is not null and not exists (select null from images i2 where i2.id=images.duplicate_id);
          delete from source_changes where not exists (select null from images where images.id=source_changes.image_id);
          delete from tag_changes where not exists (select null from images where images.id=tag_changes.image_id);
          update tag_changes set tag_id = null where tag_id is not null and not exists (select null from tags where tags.id=tag_changes.tag_id);
          update tags set aliased_tag_id = null where aliased_tag_id is not null and not exists (select null from tags t2 where t2.id=tags.aliased_tag_id);
          update user_links set tag_id = null where tag_id is not null and not exists (select null from tags where tags.id = user_links.tag_id);

          -- fix known null violations
          update comments set hidden_from_users = 'f' where hidden_from_users is null;
          update commissions set open = 'f' where open is null;
          delete from fingerprint_bans where banning_user_id is null;
          update images set favourites = 0 where favourites is null;
          update images set downvotes = 0 where downvotes is null;
          update images set upvotes = 0 where upvotes is null;
          update images set votes = 0 where votes is null;
          update images set thumbnails_generated = 'f' where thumbnails_generated is null;
          delete from messages where conversation_id is null or from_id is null;
          delete from reports where reportable_id is null or reportable_type is null;
          delete from source_changes where image_id is null;
          delete from subnet_bans where banning_user_id is null;
          update tag_changes set tag_name_cache = '' where tag_name_cache is null;
          delete from tag_changes where image_id is null;
          delete from user_bans where banning_user_id is null;
          delete from user_links where user_id is null;
          update users set serve_webm = 'f' where serve_webm is null;
          update users set comments_always_jump_to_last = 'f' where comments_always_jump_to_last is null;
          update users set no_spoilered_in_watched = 'f' where no_spoilered_in_watched is null;
          update users set show_sidebar_and_watched_images = 't' where show_sidebar_and_watched_images is null;
          update users set watch_on_new_topic = 't' where watch_on_new_topic is null;
          update users set watch_on_reply = 't' where watch_on_reply is null;
          update users set watch_on_upload = 't' where watch_on_upload is null;
          update users set messages_newest_first = 'f' where messages_newest_first is null;
          update users set topic_count = 0 where topic_count is null;
          update users set fancy_tag_field_in_settings = 'f' where fancy_tag_field_in_settings is null;

          -- fix null columns
          alter table badge_awards
            alter column user_id set not null,
            alter column badge_id set not null,
            alter column awarded_by_id set not null;

          alter table channels
            alter column short_name set not null,
            alter column title set not null,
            alter column viewers set not null,
            alter column is_live set not null,
            alter column nsfw set not null,
            alter column viewer_minutes_today set not null,
            alter column viewer_minutes_thisweek set not null,
            alter column viewer_minutes_thismonth set not null,
            alter column total_viewer_minutes set not null;

          alter table comments
            alter column body set not null,
            alter column hidden_from_users set not null;

          alter table commissions
            alter column user_id set not null,
            alter column open set not null;

          alter table conversations
            alter column title set not null,
            alter column from_id set not null,
            alter column to_id set not null,
            alter column slug set not null;

          alter table dnp_entries
            alter column reason set not null,
            alter column conditions set not null,
            alter column hide_reason set not null,
            alter column instructions set not null,
            alter column feedback set not null;

          alter table duplicate_reports
            alter column image_id set not null,
            alter column duplicate_of_image_id set not null;

          alter table filters
            alter column name set not null,
            alter column description set not null,
            alter column user_count set not null;

          alter table fingerprint_bans
            alter column reason set not null,
            alter column enabled set not null,
            alter column valid_until set not null,
            alter column banning_user_id set not null,
            alter column generated_ban_id set not null;

          alter table forums
            alter column name set not null,
            alter column short_name set not null,
            alter column description set not null,
            alter column access_level set not null;

          alter table galleries
            alter column thumbnail_id set not null,
            alter column creator_id set not null,
            alter column order_position_asc set not null;

          alter table images
            drop column if exists old_id cascade,
            drop column if exists mongo_id cascade,
            alter column score set not null,
            alter column favourites set not null,
            alter column upvotes set not null,
            alter column downvotes set not null,
            alter column votes set not null,
            alter column comments_count set not null,
            alter column processed set not null,
            alter column thumbnails_generated set not null,
            alter column duplication_checked set not null,
            alter column hidden_from_users set not null,
            alter column tag_editing_allowed set not null,
            alter column description_editing_allowed set not null,
            alter column commenting_allowed set not null,
            alter column is_animated set not null,
            alter column first_seen_at set not null,
            alter column destroyed_content set not null;

          alter table messages
            alter column body set not null,
            alter column from_id set not null,
            alter column conversation_id set not null;

          alter table mod_notes
            alter column moderator_id set not null,
            alter column notable_id set not null,
            alter column notable_type set not null,
            alter column body set not null,
            alter column deleted set not null;

          alter table notifications
            drop column if exists user_id,
            alter column action set not null,
            alter column actor_id set not null,
            alter column actor_type set not null;

          alter table posts
            alter column body set not null,
            alter column topic_position set not null,
            alter column hidden_from_users set not null,
            alter column topic_id set not null,
            alter column destroyed_content set not null;

          alter table reports
            alter column ip set not null,
            alter column reason set not null,
            alter column reportable_id set not null,
            alter column reportable_type set not null;

          alter table site_notices
            alter column title set not null,
            alter column text set not null,
            alter column link set not null,
            alter column link_text set not null,
            alter column live set not null,
            alter column start_date set not null,
            alter column finish_date set not null,
            alter column user_id set not null;

          alter table source_changes
            alter column ip set not null,
            alter column initial set not null,
            alter column image_id set not null;

          alter table subnet_bans
            alter column reason set not null,
            alter column enabled set not null,
            alter column valid_until set not null,
            alter column banning_user_id set not null,
            alter column generated_ban_id set not null;

          alter table tag_changes
            alter column tag_name_cache set default '',
            alter column added set not null,
            alter column tag_name_cache set not null,
            alter column image_id set not null;

          alter table tags
            drop column if exists implied_tag_ids,
            alter column name set not null,
            alter column slug set not null,
            alter column images_count set not null;

          alter table topics
            alter column title set not null,
            alter column sticky set not null,
            alter column slug set not null,
            alter column forum_id set not null,
            alter column hidden_from_users set not null;

          alter table user_bans
            alter column reason set not null,
            alter column enabled set not null,
            alter column valid_until set not null,
            alter column user_id set not null,
            alter column banning_user_id set not null,
            alter column generated_ban_id set not null,
            alter column override_ip_ban set not null;

          alter table user_links
            alter column aasm_state set not null,
            alter column uri set not null,
            alter column verification_code set not null,
            alter column public set not null,
            alter column user_id set not null;

          alter table user_name_changes
            alter column user_id set not null,
            alter column name set not null;

          alter table user_statistics
            alter column user_id set not null;

          alter table user_whitelists
            alter column reason set not null,
            alter column user_id set not null;

          alter table users
            alter column authentication_token set not null,
            alter column slug set not null,
            alter column role set not null,
            alter column spoiler_type set not null,
            alter column theme set not null,
            alter column images_per_page set not null,
            alter column show_large_thumbnails set not null,
            alter column show_sidebar_and_watched_images set not null,
            alter column fancy_tag_field_on_upload set not null,
            alter column fancy_tag_field_on_edit set not null,
            alter column fancy_tag_field_in_settings set not null,
            alter column autorefresh_by_default set not null,
            alter column anonymous_by_default set not null,
            alter column scale_large_images set not null,
            alter column comments_newest_first set not null,
            alter column comments_always_jump_to_last set not null,
            alter column comments_per_page set not null,
            alter column watch_on_reply set not null,
            alter column watch_on_new_topic set not null,
            alter column watch_on_upload set not null,
            alter column messages_newest_first set not null,
            alter column serve_webm set not null,
            alter column no_spoilered_in_watched set not null,
            alter column forum_posts_count set not null,
            alter column topic_count set not null,
            alter column uploads_count set not null,
            alter column votes_cast_count set not null,
            alter column comments_posted_count set not null,
            alter column metadata_updates_count set not null,
            alter column images_favourited_count set not null,
            alter column use_centered_layout set not null,
            alter column hide_default_role set not null,
            alter column show_hidden_items set not null,
            alter column hide_vote_counts set not null,
            alter column hide_advertisements set not null;

          alter table users_roles
            alter column user_id set not null,
            alter column role_id set not null;
        SQL
      end
      dir.down do
        execute <<-SQL
          alter table badge_awards
            alter column user_id drop not null,
            alter column badge_id drop not null,
            alter column awarded_by_id drop not null;

          alter table channels
            alter column short_name drop not null,
            alter column title drop not null,
            alter column viewers drop not null,
            alter column is_live drop not null,
            alter column nsfw drop not null,
            alter column viewer_minutes_today drop not null,
            alter column viewer_minutes_thisweek drop not null,
            alter column viewer_minutes_thismonth drop not null,
            alter column total_viewer_minutes drop not null;

          alter table comments
            alter column body drop not null,
            alter column hidden_from_users drop not null;

          alter table commissions
            alter column user_id drop not null,
            alter column open drop not null;

          alter table conversations
            alter column title drop not null,
            alter column from_id drop not null,
            alter column to_id drop not null,
            alter column slug drop not null;

          alter table dnp_entries
            alter column reason drop not null,
            alter column conditions drop not null,
            alter column hide_reason drop not null,
            alter column instructions drop not null,
            alter column feedback drop not null;

          alter table duplicate_reports
            alter column image_id drop not null,
            alter column duplicate_of_image_id drop not null;

          alter table filters
            alter column name drop not null,
            alter column description drop not null,
            alter column user_count drop not null;

          alter table fingerprint_bans
            alter column reason drop not null,
            alter column enabled drop not null,
            alter column valid_until drop not null,
            alter column banning_user_id drop not null,
            alter column generated_ban_id drop not null;

          alter table forums
            alter column name drop not null,
            alter column short_name drop not null,
            alter column description drop not null,
            alter column access_level drop not null;

          alter table galleries
            alter column thumbnail_id drop not null,
            alter column creator_id drop not null,
            alter column order_position_asc drop not null;

          alter table images
            alter column score drop not null,
            alter column favourites drop not null,
            alter column upvotes drop not null,
            alter column downvotes drop not null,
            alter column votes drop not null,
            alter column comments_count drop not null,
            alter column processed drop not null,
            alter column thumbnails_generated drop not null,
            alter column duplication_checked drop not null,
            alter column hidden_from_users drop not null,
            alter column tag_editing_allowed drop not null,
            alter column description_editing_allowed drop not null,
            alter column commenting_allowed drop not null,
            alter column is_animated drop not null,
            alter column first_seen_at drop not null,
            alter column destroyed_content drop not null;

          alter table messages
            alter column body drop not null,
            alter column from_id drop not null,
            alter column conversation_id drop not null;

          alter table mod_notes
            alter column moderator_id drop not null,
            alter column notable_id drop not null,
            alter column notable_type drop not null,
            alter column body drop not null,
            alter column deleted drop not null;

          alter table notifications
            alter column action drop not null,
            alter column actor_id drop not null,
            alter column actor_type drop not null;

          alter table posts
            alter column body drop not null,
            alter column topic_position drop not null,
            alter column hidden_from_users drop not null,
            alter column topic_id drop not null,
            alter column destroyed_content drop not null;

          alter table reports
            alter column ip drop not null,
            alter column reason drop not null,
            alter column reportable_id drop not null,
            alter column reportable_type drop not null;

          alter table site_notices
            alter column title drop not null,
            alter column text drop not null,
            alter column link drop not null,
            alter column link_text drop not null,
            alter column live drop not null,
            alter column start_date drop not null,
            alter column finish_date drop not null,
            alter column user_id drop not null;

          alter table source_changes
            alter column ip drop not null,
            alter column initial drop not null,
            alter column image_id drop not null;

          alter table subnet_bans
            alter column reason drop not null,
            alter column enabled drop not null,
            alter column valid_until drop not null,
            alter column banning_user_id drop not null,
            alter column generated_ban_id drop not null;

          alter table tag_changes
            alter column tag_name_cache set default '',
            alter column added drop not null,
            alter column tag_name_cache drop not null,
            alter column image_id drop not null;

          alter table tags
            alter column name drop not null,
            alter column slug drop not null,
            alter column images_count drop not null;

          alter table topics
            alter column title drop not null,
            alter column sticky drop not null,
            alter column slug drop not null,
            alter column forum_id drop not null,
            alter column hidden_from_users drop not null;

          alter table user_bans
            alter column reason drop not null,
            alter column enabled drop not null,
            alter column valid_until drop not null,
            alter column user_id drop not null,
            alter column banning_user_id drop not null,
            alter column generated_ban_id drop not null,
            alter column override_ip_ban drop not null;

          alter table user_links
            alter column aasm_state drop not null,
            alter column uri drop not null,
            alter column verification_code drop not null,
            alter column public drop not null,
            alter column user_id drop not null;

          alter table user_name_changes
            alter column user_id drop not null,
            alter column name drop not null;

          alter table user_statistics
            alter column user_id drop not null;

          alter table user_whitelists
            alter column reason drop not null,
            alter column user_id drop not null;

          alter table users
            alter column authentication_token drop not null,
            alter column slug drop not null,
            alter column role drop not null,
            alter column spoiler_type drop not null,
            alter column theme drop not null,
            alter column images_per_page drop not null,
            alter column show_large_thumbnails drop not null,
            alter column show_sidebar_and_watched_images drop not null,
            alter column fancy_tag_field_on_upload drop not null,
            alter column fancy_tag_field_on_edit drop not null,
            alter column fancy_tag_field_in_settings drop not null,
            alter column autorefresh_by_default drop not null,
            alter column anonymous_by_default drop not null,
            alter column scale_large_images drop not null,
            alter column comments_newest_first drop not null,
            alter column comments_always_jump_to_last drop not null,
            alter column comments_per_page drop not null,
            alter column watch_on_reply drop not null,
            alter column watch_on_new_topic drop not null,
            alter column watch_on_upload drop not null,
            alter column messages_newest_first drop not null,
            alter column serve_webm drop not null,
            alter column no_spoilered_in_watched drop not null,
            alter column forum_posts_count drop not null,
            alter column topic_count drop not null,
            alter column uploads_count drop not null,
            alter column votes_cast_count drop not null,
            alter column comments_posted_count drop not null,
            alter column metadata_updates_count drop not null,
            alter column images_favourited_count drop not null,
            alter column use_centered_layout drop not null,
            alter column hide_default_role drop not null,
            alter column show_hidden_items drop not null,
            alter column hide_vote_counts drop not null,
            alter column hide_advertisements drop not null;

          alter table users_roles
            alter column user_id drop not null,
            alter column role_id drop not null;
        SQL
      end
    end

    remove_index :poll_options, [:poll_id]
    remove_index :poll_votes, [:poll_option_id]
    remove_index :posts, [:topic_id, :created_at]
    remove_index :roles, [:name]
    remove_index :unread_notifications, [:notification_id]
    remove_index :user_fingerprints, [:fingerprint]
    remove_index :user_ips, [:ip]
    remove_index :user_ips, [:user_id]
    remove_index :users_roles, [:user_id, :role_id]

    add_index :badge_awards, :badge_id
    add_index :badge_awards, :awarded_by_id
    add_index :channels, :associated_artist_tag_id
    add_index :comments, :user_id
    add_index :comments, :deleted_by_id, where: 'deleted_by_id is not null'
    add_index :commission_items, :example_image_id
    add_index :commissions, :sheet_image_id
    add_index :duplicate_reports, :user_id
    add_index :duplicate_reports, :modifier_id
    add_index :fingerprint_bans, :banning_user_id
    add_index :forums, :last_post_id
    add_index :forums, :last_topic_id
    add_index :galleries, :thumbnail_id
    add_index :galleries, :creator_id
    add_index :images, :duplicate_id, where: 'duplicate_id is not null'
    add_index :images, :user_id
    add_index :images, :deleted_by_id, where: 'deleted_by_id is not null'
    add_index :messages, :from_id
    add_index :polls, :deleted_by_id, where: 'deleted_by_id is not null'
    add_index :posts, :deleted_by_id, where: 'deleted_by_id is not null'
    add_index :reports, :admin_id
    add_index :site_notices, :user_id
    add_index :subnet_bans, :banning_user_id
    add_index :topics, :user_id
    add_index :topics, :deleted_by_id, where: 'deleted_by_id is not null'
    add_index :topics, :locked_by_id, where: 'locked_by_id is not null'
    add_index :topics, :last_post_id
    add_index :user_bans, :banning_user_id
    add_index :user_links, :verified_by_user_id
    add_index :user_links, :contacted_by_user_id
    add_index :users, :deleted_by_user_id, where: 'deleted_by_user_id is not null'
    add_index :users_roles, [:user_id, :role_id], unique: true
    add_index :users_roles, :role_id

    remove_foreign_key :commission_items, :commissions
    remove_foreign_key :commissions, :users
    remove_foreign_key :dnp_entries, :tags
    remove_foreign_key :dnp_entries, :users, column: :modifying_user_id
    remove_foreign_key :dnp_entries, :users, column: :requesting_user_id
    remove_foreign_key :gallery_interactions, :galleries
    remove_foreign_key :gallery_interactions, :images
    remove_foreign_key :mod_notes, :users, column: :moderator_id
    remove_foreign_key :unread_notifications, :notifications, on_delete: :cascade
    remove_foreign_key :unread_notifications, :users, on_delete: :cascade
    remove_foreign_key :user_name_changes, :users

    add_foreign_key :commission_items, :commissions, on_delete: :cascade, on_update: :cascade
    add_foreign_key :commissions, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :dnp_entries, :tags, on_delete: :cascade, on_update: :cascade
    add_foreign_key :dnp_entries, :users, column: :modifying_user_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :dnp_entries, :users, column: :requesting_user_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :gallery_interactions, :galleries, on_delete: :cascade, on_update: :cascade
    add_foreign_key :gallery_interactions, :images, on_delete: :restrict, on_update: :cascade
    add_foreign_key :mod_notes, :users, column: :moderator_id, on_delete: :restrict, on_update: :cascade
    add_foreign_key :unread_notifications, :notifications, on_delete: :cascade, on_update: :cascade
    add_foreign_key :unread_notifications, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_name_changes, :users, on_delete: :cascade, on_update: :cascade

    add_foreign_key :badge_awards, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :badge_awards, :badges, on_delete: :cascade, on_update: :cascade
    add_foreign_key :badge_awards, :users, column: :awarded_by_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :channels, :tags, column: :associated_artist_tag_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :comments, :users, on_delete: :nullify, on_update: :cascade
    add_foreign_key :comments, :images, on_delete: :cascade, on_update: :cascade
    add_foreign_key :comments, :users, column: :deleted_by_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :commission_items, :images, column: :example_image_id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :commissions, :images, column: :sheet_image_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :conversations, :users, column: :from_id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :conversations, :users, column: :to_id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :donations, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :duplicate_reports, :images, on_delete: :cascade, on_update: :cascade
    add_foreign_key :duplicate_reports, :images, column: :duplicate_of_image_id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :duplicate_reports, :users, on_delete: :nullify, on_update: :cascade
    add_foreign_key :duplicate_reports, :users, column: :modifier_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :filters, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :fingerprint_bans, :users, column: :banning_user_id, on_delete: :restrict, on_update: :cascade
    add_foreign_key :forums, :posts, column: :last_post_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :forums, :topics, column: :last_topic_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :galleries, :images, column: :thumbnail_id, on_delete: :restrict, on_update: :cascade
    add_foreign_key :galleries, :users, column: :creator_id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :images, :images, column: :duplicate_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :images, :users, on_delete: :nullify, on_update: :cascade
    add_foreign_key :images, :users, column: :deleted_by_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :messages, :users, column: :from_id, on_delete: :restrict, on_update: :cascade
    add_foreign_key :polls, :users, column: :deleted_by_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :posts, :users, on_delete: :nullify, on_update: :cascade
    add_foreign_key :posts, :topics, on_delete: :cascade, on_update: :cascade
    add_foreign_key :posts, :users, column: :deleted_by_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :reports, :users, on_delete: :nullify, on_update: :cascade
    add_foreign_key :reports, :users, column: :admin_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :site_notices, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :source_changes, :users, on_delete: :nullify, on_update: :cascade
    add_foreign_key :source_changes, :images, on_delete: :cascade, on_update: :cascade
    add_foreign_key :subnet_bans, :users, column: :banning_user_id, on_delete: :restrict, on_update: :cascade
    add_foreign_key :tag_changes, :users, on_delete: :nullify, on_update: :cascade
    add_foreign_key :tag_changes, :tags, on_delete: :nullify, on_update: :cascade
    add_foreign_key :tag_changes, :images, on_delete: :cascade, on_update: :cascade
    add_foreign_key :tags, :tags, column: :aliased_tag_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :topics, :forums, on_delete: :cascade, on_update: :cascade
    add_foreign_key :topics, :users, on_delete: :nullify, on_update: :cascade
    add_foreign_key :topics, :users, column: :deleted_by_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :topics, :users, column: :locked_by_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :topics, :posts, column: :last_post_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :user_bans, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_bans, :users, column: :banning_user_id, on_delete: :restrict, on_update: :cascade
    add_foreign_key :user_fingerprints, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_interactions, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_interactions, :images, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_ips, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_links, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_links, :users, column: :verified_by_user_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :user_links, :users, column: :contacted_by_user_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :user_links, :tags, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_statistics, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :user_whitelists, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :users, :users, column: :deleted_by_user_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :users, :filters, column: :current_filter_id, on_delete: :restrict, on_update: :cascade
    add_foreign_key :users_roles, :users, on_delete: :cascade, on_update: :cascade
    add_foreign_key :users_roles, :roles, on_delete: :cascade, on_update: :cascade
  end
end
