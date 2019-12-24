# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_08_10_011525) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "adverts", id: :serial, force: :cascade do |t|
    t.string "image"
    t.string "link"
    t.string "title"
    t.integer "clicks", default: 0
    t.integer "impressions", default: 0
    t.boolean "live", default: false
    t.datetime "start_date"
    t.datetime "finish_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "restrictions"
    t.string "notes"
    t.index ["live"], name: "index_adverts_on_live"
    t.index ["restrictions"], name: "index_adverts_on_restrictions"
    t.index ["start_date", "finish_date"], name: "index_adverts_on_start_date_and_finish_date"
  end

  create_table "badge_awards", id: :serial, force: :cascade do |t|
    t.string "label"
    t.datetime "awarded_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "badge_id", null: false
    t.integer "awarded_by_id", null: false
    t.string "reason"
    t.string "badge_name"
    t.index ["awarded_by_id"], name: "index_badge_awards_on_awarded_by_id"
    t.index ["badge_id"], name: "index_badge_awards_on_badge_id"
    t.index ["user_id"], name: "index_badge_awards_on_user_id"
  end

  create_table "badges", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.string "description", null: false
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disable_award", default: false, null: false
    t.boolean "priority", default: false
  end

  create_table "channel_subscriptions", id: false, force: :cascade do |t|
    t.integer "channel_id", null: false
    t.integer "user_id", null: false
    t.index ["channel_id", "user_id"], name: "index_channel_subscriptions_on_channel_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_channel_subscriptions_on_user_id"
  end

  create_table "channels", id: :serial, force: :cascade do |t|
    t.string "short_name", null: false
    t.string "title", null: false
    t.string "description"
    t.string "channel_image"
    t.string "tags"
    t.integer "viewers", default: 0, null: false
    t.boolean "nsfw", default: false, null: false
    t.boolean "is_live", default: false, null: false
    t.datetime "last_fetched_at"
    t.datetime "next_check_at"
    t.datetime "last_live_at"
    t.integer "watcher_ids", default: [], null: false, array: true
    t.integer "watcher_count", default: 0, null: false
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "associated_artist_tag_id"
    t.integer "viewer_minutes_today", default: 0, null: false
    t.integer "viewer_minutes_thisweek", default: 0, null: false
    t.integer "viewer_minutes_thismonth", default: 0, null: false
    t.integer "total_viewer_minutes", default: 0, null: false
    t.string "banner_image"
    t.integer "remote_stream_id"
    t.string "thumbnail_url", default: ""
    t.index ["associated_artist_tag_id"], name: "index_channels_on_associated_artist_tag_id"
    t.index ["is_live"], name: "index_channels_on_is_live"
    t.index ["last_fetched_at"], name: "index_channels_on_last_fetched_at"
    t.index ["next_check_at"], name: "index_channels_on_next_check_at"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.string "body", null: false
    t.inet "ip"
    t.string "fingerprint"
    t.string "user_agent", default: ""
    t.string "referrer", default: ""
    t.boolean "anonymous", default: false
    t.boolean "hidden_from_users", default: false, null: false
    t.integer "user_id"
    t.integer "deleted_by_id"
    t.integer "image_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "edit_reason"
    t.datetime "edited_at"
    t.string "deletion_reason", default: "", null: false
    t.boolean "destroyed_content", default: false
    t.string "name_at_post_time"
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["deleted_by_id"], name: "index_comments_on_deleted_by_id", where: "(deleted_by_id IS NOT NULL)"
    t.index ["image_id"], name: "index_comments_on_image_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "commission_items", id: :serial, force: :cascade do |t|
    t.integer "commission_id"
    t.string "item_type"
    t.string "description"
    t.decimal "base_price"
    t.string "add_ons"
    t.integer "example_image_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commission_id"], name: "index_commission_items_on_commission_id"
    t.index ["example_image_id"], name: "index_commission_items_on_example_image_id"
    t.index ["item_type"], name: "index_commission_items_on_item_type"
  end

  create_table "commissions", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "open", null: false
    t.string "categories", default: [], null: false, array: true
    t.string "information"
    t.string "contact"
    t.integer "sheet_image_id"
    t.string "will_create"
    t.string "will_not_create"
    t.integer "commission_items_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["categories"], name: "index_commissions_on_categories"
    t.index ["open"], name: "index_commissions_on_open"
    t.index ["sheet_image_id"], name: "index_commissions_on_sheet_image_id"
    t.index ["user_id"], name: "index_commissions_on_user_id"
  end

  create_table "conversations", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.boolean "to_read", default: false, null: false
    t.boolean "from_read", default: true, null: false
    t.boolean "to_hidden", default: false, null: false
    t.boolean "from_hidden", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "from_id", null: false
    t.integer "to_id", null: false
    t.string "slug", null: false
    t.datetime "last_message_at", null: false
    t.index ["created_at", "from_hidden"], name: "index_conversations_on_created_at_and_from_hidden"
    t.index ["from_id"], name: "index_conversations_on_from_id"
    t.index ["to_id"], name: "index_conversations_on_to_id"
  end

  create_table "dnp_entries", id: :serial, force: :cascade do |t|
    t.integer "requesting_user_id", null: false
    t.integer "modifying_user_id"
    t.integer "tag_id", null: false
    t.string "aasm_state", default: "requested", null: false
    t.string "dnp_type", null: false
    t.string "conditions", null: false
    t.string "reason", null: false
    t.boolean "hide_reason", default: false, null: false
    t.string "instructions", null: false
    t.string "feedback", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["modifying_user_id"], name: "index_dnp_entries_on_modifying_user_id"
    t.index ["requesting_user_id"], name: "index_dnp_entries_on_requesting_user_id"
    t.index ["tag_id"], name: "index_dnp_entries_on_tag_id"
  end

  create_table "donations", id: :serial, force: :cascade do |t|
    t.string "email"
    t.decimal "amount"
    t.decimal "fee"
    t.string "txn_id"
    t.string "receipt_id"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_donations_on_user_id"
  end

  create_table "duplicate_reports", id: :serial, force: :cascade do |t|
    t.string "reason"
    t.string "state", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "image_id", null: false
    t.integer "duplicate_of_image_id", null: false
    t.integer "user_id"
    t.integer "modifier_id"
    t.index ["created_at"], name: "index_duplicate_reports_on_created_at"
    t.index ["duplicate_of_image_id"], name: "index_duplicate_reports_on_duplicate_of_image_id"
    t.index ["image_id"], name: "index_duplicate_reports_on_image_id"
    t.index ["modifier_id"], name: "index_duplicate_reports_on_modifier_id"
    t.index ["state"], name: "index_duplicate_reports_on_state"
    t.index ["user_id"], name: "index_duplicate_reports_on_user_id"
  end

  create_table "filters", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.boolean "system", default: false, null: false
    t.boolean "public", default: false, null: false
    t.string "hidden_complex_str"
    t.string "spoilered_complex_str"
    t.integer "hidden_tag_ids", default: [], null: false, array: true
    t.integer "spoilered_tag_ids", default: [], null: false, array: true
    t.integer "user_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_filters_on_user_id"
  end

  create_table "fingerprint_bans", id: :serial, force: :cascade do |t|
    t.string "reason", null: false
    t.string "note"
    t.boolean "enabled", default: true, null: false
    t.datetime "valid_until", null: false
    t.string "fingerprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "banning_user_id", null: false
    t.string "generated_ban_id", null: false
    t.index ["banning_user_id"], name: "index_fingerprint_bans_on_banning_user_id"
    t.index ["created_at"], name: "index_fingerprint_bans_on_created_at"
    t.index ["fingerprint"], name: "index_fingerprint_bans_on_fingerprint"
  end

  create_table "forum_subscriptions", id: false, force: :cascade do |t|
    t.integer "forum_id", null: false
    t.integer "user_id", null: false
    t.index ["forum_id", "user_id"], name: "index_forum_subscriptions_on_forum_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_forum_subscriptions_on_user_id"
  end

  create_table "forums", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name", null: false
    t.string "description", null: false
    t.string "access_level", default: "normal", null: false
    t.integer "topic_count", default: 0, null: false
    t.integer "post_count", default: 0, null: false
    t.integer "watcher_ids", default: [], null: false, array: true
    t.integer "watcher_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_post_id"
    t.integer "last_topic_id"
    t.index ["last_post_id"], name: "index_forums_on_last_post_id"
    t.index ["last_topic_id"], name: "index_forums_on_last_topic_id"
    t.index ["short_name"], name: "index_forums_on_short_name"
  end

  create_table "galleries", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.string "spoiler_warning", default: "", null: false
    t.string "description", default: "", null: false
    t.integer "thumbnail_id", null: false
    t.integer "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "watcher_ids", default: [], null: false, array: true
    t.integer "watcher_count", default: 0, null: false
    t.integer "image_count", default: 0, null: false
    t.boolean "order_position_asc", default: false, null: false
    t.index ["creator_id"], name: "index_galleries_on_creator_id"
    t.index ["thumbnail_id"], name: "index_galleries_on_thumbnail_id"
  end

  create_table "gallery_interactions", id: :serial, force: :cascade do |t|
    t.integer "position", null: false
    t.integer "image_id", null: false
    t.integer "gallery_id", null: false
    t.index ["gallery_id"], name: "index_gallery_interactions_on_gallery_id"
    t.index ["image_id"], name: "index_gallery_interactions_on_image_id"
    t.index ["position"], name: "index_gallery_interactions_on_position"
  end

  create_table "gallery_subscriptions", id: false, force: :cascade do |t|
    t.integer "gallery_id", null: false
    t.integer "user_id", null: false
    t.index ["gallery_id", "user_id"], name: "index_gallery_subscriptions_on_gallery_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_gallery_subscriptions_on_user_id"
  end

  create_table "image_faves", id: false, force: :cascade do |t|
    t.bigint "image_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.index ["image_id", "user_id"], name: "index_image_faves_on_image_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_image_faves_on_user_id"
  end

  create_table "image_features", force: :cascade do |t|
    t.bigint "image_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_image_features_on_created_at"
    t.index ["image_id"], name: "index_image_features_on_image_id"
    t.index ["user_id"], name: "index_image_features_on_user_id"
  end

  create_table "image_hides", id: false, force: :cascade do |t|
    t.bigint "image_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.index ["image_id", "user_id"], name: "index_image_hides_on_image_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_image_hides_on_user_id"
  end

  create_table "image_intensities", force: :cascade do |t|
    t.bigint "image_id", null: false
    t.float "nw", null: false
    t.float "ne", null: false
    t.float "sw", null: false
    t.float "se", null: false
    t.index ["image_id"], name: "index_image_intensities_on_image_id", unique: true
    t.index ["nw", "ne", "sw", "se"], name: "image_intensities_index"
  end

  create_table "image_subscriptions", id: false, force: :cascade do |t|
    t.integer "image_id", null: false
    t.integer "user_id", null: false
    t.index ["image_id", "user_id"], name: "index_image_subscriptions_on_image_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_image_subscriptions_on_user_id"
  end

  create_table "image_taggings", id: false, force: :cascade do |t|
    t.bigint "image_id", null: false
    t.bigint "tag_id", null: false
    t.index ["image_id", "tag_id"], name: "index_image_taggings_on_image_id_and_tag_id", unique: true
    t.index ["tag_id"], name: "index_image_taggings_on_tag_id"
  end

  create_table "image_votes", id: false, force: :cascade do |t|
    t.bigint "image_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.boolean "up", null: false
    t.index ["image_id", "user_id"], name: "index_image_votes_on_image_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_image_votes_on_user_id"
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.string "image"
    t.string "image_name"
    t.integer "image_width"
    t.integer "image_height"
    t.integer "image_size"
    t.string "image_format"
    t.string "image_mime_type"
    t.float "image_aspect_ratio"
    t.inet "ip"
    t.string "fingerprint"
    t.string "user_agent", default: ""
    t.string "referrer", default: ""
    t.boolean "anonymous", default: false
    t.integer "score", default: 0, null: false
    t.integer "faves_count", default: 0, null: false
    t.integer "upvotes_count", default: 0, null: false
    t.integer "downvotes_count", default: 0, null: false
    t.integer "votes_count", default: 0, null: false
    t.integer "watcher_ids", default: [], null: false, array: true
    t.integer "watcher_count", default: 0, null: false
    t.string "source_url"
    t.string "description", default: "", null: false
    t.string "image_sha512_hash"
    t.string "image_orig_sha512_hash"
    t.string "deletion_reason"
    t.string "tag_list_cache"
    t.string "tag_list_plus_alias_cache"
    t.string "file_name_cache"
    t.integer "duplicate_id"
    t.integer "tag_ids", default: [], null: false, array: true
    t.integer "comments_count", default: 0, null: false
    t.boolean "processed", default: false, null: false
    t.boolean "thumbnails_generated", default: false, null: false
    t.boolean "duplication_checked", default: false, null: false
    t.boolean "hidden_from_users", default: false, null: false
    t.boolean "tag_editing_allowed", default: true, null: false
    t.boolean "description_editing_allowed", default: true, null: false
    t.boolean "commenting_allowed", default: true, null: false
    t.boolean "is_animated", null: false
    t.datetime "first_seen_at", null: false
    t.datetime "featured_on"
    t.float "se_intensity"
    t.float "sw_intensity"
    t.float "ne_intensity"
    t.float "nw_intensity"
    t.float "average_intensity"
    t.integer "user_id"
    t.integer "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "destroyed_content", default: false, null: false
    t.string "hidden_image_key"
    t.string "scratchpad"
    t.integer "hides_count", default: 0, null: false
    t.index ["created_at"], name: "index_images_on_created_at"
    t.index ["deleted_by_id"], name: "index_images_on_deleted_by_id", where: "(deleted_by_id IS NOT NULL)"
    t.index ["duplicate_id"], name: "index_images_on_duplicate_id", where: "(duplicate_id IS NOT NULL)"
    t.index ["featured_on"], name: "index_images_on_featured_on"
    t.index ["first_seen_at"], name: "index_images_on_first_seen_at"
    t.index ["image_orig_sha512_hash"], name: "index_images_on_image_orig_sha512_hash"
    t.index ["se_intensity", "sw_intensity", "ne_intensity", "nw_intensity", "average_intensity"], name: "intensities_index"
    t.index ["tag_ids"], name: "index_images_on_tag_ids", using: :gin
    t.index ["updated_at"], name: "index_images_on_updated_at"
    t.index ["user_id"], name: "index_images_on_user_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "from_id", null: false
    t.integer "conversation_id", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["from_id"], name: "index_messages_on_from_id"
  end

  create_table "mod_notes", id: :serial, force: :cascade do |t|
    t.integer "moderator_id", null: false
    t.integer "notable_id", null: false
    t.string "notable_type", null: false
    t.text "body", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["moderator_id"], name: "index_mod_notes_on_moderator_id"
    t.index ["notable_type", "notable_id"], name: "index_mod_notes_on_notable_type_and_notable_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.string "action", null: false
    t.integer "watcher_ids", default: [], null: false, array: true
    t.integer "actor_id", null: false
    t.string "actor_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "actor_child_id"
    t.string "actor_child_type"
    t.index ["actor_id", "actor_type"], name: "index_notifications_on_actor_id_and_actor_type"
  end

  create_table "poll_options", id: :serial, force: :cascade do |t|
    t.string "label", limit: 80, null: false
    t.integer "vote_count", default: 0, null: false
    t.integer "poll_id", null: false
    t.index ["poll_id", "label"], name: "index_poll_options_on_poll_id_and_label", unique: true
  end

  create_table "poll_votes", id: :serial, force: :cascade do |t|
    t.integer "rank"
    t.integer "poll_option_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.index ["poll_option_id", "user_id"], name: "index_poll_votes_on_poll_option_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_poll_votes_on_user_id"
  end

  create_table "polls", id: :serial, force: :cascade do |t|
    t.string "title", limit: 140, null: false
    t.string "vote_method", limit: 8, null: false
    t.datetime "active_until", null: false
    t.integer "total_votes", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden_from_users", default: false, null: false
    t.integer "deleted_by_id"
    t.string "deletion_reason", default: "", null: false
    t.integer "topic_id", null: false
    t.index ["deleted_by_id"], name: "index_polls_on_deleted_by_id", where: "(deleted_by_id IS NOT NULL)"
    t.index ["topic_id"], name: "index_polls_on_topic_id"
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.string "body", null: false
    t.string "edit_reason"
    t.inet "ip"
    t.string "fingerprint"
    t.string "user_agent", default: ""
    t.string "referrer", default: ""
    t.integer "topic_position", null: false
    t.boolean "hidden_from_users", default: false, null: false
    t.boolean "anonymous", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "topic_id", null: false
    t.integer "deleted_by_id"
    t.datetime "edited_at"
    t.string "deletion_reason", default: "", null: false
    t.boolean "destroyed_content", default: false, null: false
    t.string "name_at_post_time"
    t.index ["deleted_by_id"], name: "index_posts_on_deleted_by_id", where: "(deleted_by_id IS NOT NULL)"
    t.index ["topic_id", "created_at"], name: "index_posts_on_topic_id_and_created_at"
    t.index ["topic_id", "topic_position"], name: "index_posts_on_topic_id_and_topic_position"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "reports", id: :serial, force: :cascade do |t|
    t.inet "ip", null: false
    t.string "fingerprint"
    t.string "user_agent", default: ""
    t.string "referrer", default: ""
    t.string "reason", null: false
    t.string "state", default: "open", null: false
    t.boolean "open", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "admin_id"
    t.integer "reportable_id", null: false
    t.string "reportable_type", null: false
    t.index ["admin_id"], name: "index_reports_on_admin_id"
    t.index ["created_at"], name: "index_reports_on_created_at"
    t.index ["open"], name: "index_reports_on_open"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
  end

  create_table "site_notices", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.string "text", null: false
    t.string "link", null: false
    t.string "link_text", null: false
    t.boolean "live", default: false, null: false
    t.datetime "start_date", null: false
    t.datetime "finish_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["start_date", "finish_date"], name: "index_site_notices_on_start_date_and_finish_date"
    t.index ["user_id"], name: "index_site_notices_on_user_id"
  end

  create_table "source_changes", id: :serial, force: :cascade do |t|
    t.inet "ip", null: false
    t.string "fingerprint"
    t.string "user_agent", default: ""
    t.string "referrer", default: ""
    t.string "new_value"
    t.boolean "initial", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "image_id", null: false
    t.index ["image_id"], name: "index_source_changes_on_image_id"
    t.index ["ip"], name: "index_source_changes_on_ip"
    t.index ["user_id"], name: "index_source_changes_on_user_id"
  end

  create_table "static_page_versions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "static_page_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "title", null: false
    t.text "slug", null: false
    t.text "body", null: false
    t.index ["static_page_id"], name: "index_static_page_versions_on_static_page_id"
    t.index ["user_id"], name: "index_static_page_versions_on_user_id"
  end

  create_table "static_pages", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "title", null: false
    t.text "slug", null: false
    t.text "body", null: false
    t.index ["slug"], name: "index_static_pages_on_slug", unique: true
    t.index ["title"], name: "index_static_pages_on_title", unique: true
  end

  create_table "subnet_bans", id: :serial, force: :cascade do |t|
    t.string "reason", null: false
    t.string "note"
    t.boolean "enabled", default: true, null: false
    t.datetime "valid_until", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "banning_user_id", null: false
    t.inet "specification"
    t.string "generated_ban_id", null: false
    t.index ["banning_user_id"], name: "index_subnet_bans_on_banning_user_id"
    t.index ["created_at"], name: "index_subnet_bans_on_created_at"
  end

  create_table "tag_changes", id: :serial, force: :cascade do |t|
    t.inet "ip"
    t.string "fingerprint"
    t.string "user_agent", default: ""
    t.string "referrer", default: ""
    t.boolean "added", null: false
    t.string "tag_name_cache", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "tag_id"
    t.integer "image_id", null: false
    t.index ["image_id"], name: "index_tag_changes_on_image_id"
    t.index ["tag_id"], name: "index_tag_changes_on_tag_id"
    t.index ["user_id"], name: "index_tag_changes_on_user_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "description", default: ""
    t.string "short_description", default: ""
    t.string "namespace"
    t.string "name_in_namespace"
    t.integer "images_count", default: 0, null: false
    t.string "image"
    t.string "image_format"
    t.string "image_mime_type"
    t.integer "aliased_tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.string "mod_notes"
    t.index ["aliased_tag_id"], name: "index_tags_on_aliased_tag_id"
    t.index ["name"], name: "index_tags_on_name"
    t.index ["slug"], name: "index_tags_on_slug"
  end

  create_table "tags_implied_tags", id: false, force: :cascade do |t|
    t.integer "tag_id", null: false
    t.integer "implied_tag_id", null: false
    t.index ["implied_tag_id"], name: "index_tags_implied_tags_on_implied_tag_id"
    t.index ["tag_id", "implied_tag_id"], name: "index_tags_implied_tags_on_tag_id_and_implied_tag_id", unique: true
  end

  create_table "topic_subscriptions", id: false, force: :cascade do |t|
    t.integer "topic_id", null: false
    t.integer "user_id", null: false
    t.index ["topic_id", "user_id"], name: "index_topic_subscriptions_on_topic_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_topic_subscriptions_on_user_id"
  end

  create_table "topics", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.integer "post_count", default: 0, null: false
    t.integer "view_count", default: 0, null: false
    t.boolean "sticky", default: false, null: false
    t.datetime "last_replied_to_at"
    t.datetime "locked_at"
    t.string "deletion_reason"
    t.string "lock_reason"
    t.string "slug", null: false
    t.boolean "anonymous", default: false
    t.integer "watcher_ids", default: [], null: false, array: true
    t.integer "watcher_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "forum_id", null: false
    t.integer "user_id"
    t.integer "deleted_by_id"
    t.integer "locked_by_id"
    t.integer "last_post_id"
    t.boolean "hidden_from_users", default: false, null: false
    t.index ["deleted_by_id"], name: "index_topics_on_deleted_by_id", where: "(deleted_by_id IS NOT NULL)"
    t.index ["forum_id"], name: "index_topics_on_forum_id"
    t.index ["hidden_from_users"], name: "index_topics_on_hidden_from_users"
    t.index ["last_post_id"], name: "index_topics_on_last_post_id"
    t.index ["last_replied_to_at"], name: "index_topics_on_last_replied_to_at"
    t.index ["locked_by_id"], name: "index_topics_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["slug"], name: "index_topics_on_slug"
    t.index ["sticky"], name: "index_topics_on_sticky"
    t.index ["user_id"], name: "index_topics_on_user_id"
  end

  create_table "unread_notifications", id: :serial, force: :cascade do |t|
    t.integer "notification_id", null: false
    t.integer "user_id", null: false
    t.index ["notification_id", "user_id"], name: "index_unread_notifications_on_notification_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_unread_notifications_on_user_id"
  end

  create_table "user_bans", id: :serial, force: :cascade do |t|
    t.string "reason", null: false
    t.string "note"
    t.boolean "enabled", default: true, null: false
    t.datetime "valid_until", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "banning_user_id", null: false
    t.string "generated_ban_id", null: false
    t.boolean "override_ip_ban", default: false, null: false
    t.index ["banning_user_id"], name: "index_user_bans_on_banning_user_id"
    t.index ["created_at"], name: "index_user_bans_on_created_at"
    t.index ["user_id"], name: "index_user_bans_on_user_id"
  end

  create_table "user_fingerprints", id: :serial, force: :cascade do |t|
    t.string "fingerprint", null: false
    t.integer "uses", default: 0, null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.integer "user_id", null: false
    t.index ["fingerprint", "user_id"], name: "index_user_fingerprints_on_fingerprint_and_user_id", unique: true
    t.index ["user_id"], name: "index_user_fingerprints_on_user_id"
  end

  create_table "user_ips", id: :serial, force: :cascade do |t|
    t.inet "ip", null: false
    t.integer "uses", default: 0, null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.integer "user_id", null: false
    t.index ["ip", "user_id"], name: "index_user_ips_on_ip_and_user_id", unique: true
    t.index ["updated_at"], name: "index_user_ips_on_updated_at"
    t.index ["user_id", "updated_at"], name: "index_user_ips_on_user_id_and_updated_at", order: { updated_at: :desc }
  end

  create_table "user_links", id: :serial, force: :cascade do |t|
    t.string "aasm_state", null: false
    t.string "uri", null: false
    t.string "hostname"
    t.string "path"
    t.string "verification_code", null: false
    t.boolean "public", default: true, null: false
    t.datetime "next_check_at"
    t.datetime "contacted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "verified_by_user_id"
    t.integer "contacted_by_user_id"
    t.integer "tag_id"
    t.index ["aasm_state"], name: "index_user_links_on_aasm_state"
    t.index ["contacted_by_user_id"], name: "index_user_links_on_contacted_by_user_id"
    t.index ["next_check_at"], name: "index_user_links_on_next_check_at"
    t.index ["tag_id"], name: "index_user_links_on_tag_id"
    t.index ["uri", "tag_id", "user_id"], name: "index_user_links_on_uri_tag_id_user_id", unique: true, where: "((aasm_state)::text <> 'rejected'::text)"
    t.index ["user_id"], name: "index_user_links_on_user_id"
    t.index ["verified_by_user_id"], name: "index_user_links_on_verified_by_user_id"
  end

  create_table "user_name_changes", id: :serial, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_name_changes_on_user_id"
  end

  create_table "user_statistics", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "day", default: 0, null: false
    t.integer "uploads", default: 0, null: false
    t.integer "votes_cast", default: 0, null: false
    t.integer "comments_posted", default: 0, null: false
    t.integer "metadata_updates", default: 0, null: false
    t.integer "images_favourited", default: 0, null: false
    t.integer "forum_posts", default: 0, null: false
    t.index ["user_id"], name: "index_user_statistics_on_user_id"
  end

  create_table "user_whitelists", id: :serial, force: :cascade do |t|
    t.string "reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_user_whitelists_on_user_id", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "authentication_token", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "role", default: "user", null: false
    t.string "description"
    t.string "avatar"
    t.string "spoiler_type", default: "static", null: false
    t.string "theme", default: "default", null: false
    t.integer "images_per_page", default: 15, null: false
    t.boolean "show_large_thumbnails", default: true, null: false
    t.boolean "show_sidebar_and_watched_images", default: true, null: false
    t.boolean "fancy_tag_field_on_upload", default: true, null: false
    t.boolean "fancy_tag_field_on_edit", default: true, null: false
    t.boolean "fancy_tag_field_in_settings", default: true, null: false
    t.boolean "autorefresh_by_default", default: false, null: false
    t.boolean "anonymous_by_default", default: false, null: false
    t.boolean "scale_large_images", default: true, null: false
    t.boolean "comments_newest_first", default: true, null: false
    t.boolean "comments_always_jump_to_last", default: false, null: false
    t.integer "comments_per_page", default: 20, null: false
    t.boolean "watch_on_reply", default: true, null: false
    t.boolean "watch_on_new_topic", default: true, null: false
    t.boolean "watch_on_upload", default: true, null: false
    t.boolean "messages_newest_first", default: false, null: false
    t.boolean "serve_webm", default: false, null: false
    t.boolean "no_spoilered_in_watched", default: false, null: false
    t.string "watched_images_query_str", default: "", null: false
    t.string "watched_images_exclude_str", default: "", null: false
    t.integer "forum_posts_count", default: 0, null: false
    t.integer "topic_count", default: 0, null: false
    t.integer "recent_filter_ids", default: [], null: false, array: true
    t.integer "unread_notification_ids", default: [], null: false, array: true
    t.integer "watched_tag_ids", default: [], null: false, array: true
    t.integer "deleted_by_user_id"
    t.integer "current_filter_id"
    t.integer "failed_attempts"
    t.string "unlock_token"
    t.datetime "locked_at"
    t.integer "uploads_count", default: 0, null: false
    t.integer "votes_cast_count", default: 0, null: false
    t.integer "comments_posted_count", default: 0, null: false
    t.integer "metadata_updates_count", default: 0, null: false
    t.integer "images_favourited_count", default: 0, null: false
    t.datetime "last_donation_at"
    t.text "scratchpad"
    t.boolean "use_centered_layout", default: false, null: false
    t.string "secondary_role"
    t.boolean "hide_default_role", default: false, null: false
    t.string "personal_title"
    t.boolean "show_hidden_items", default: false, null: false
    t.boolean "hide_vote_counts", default: false, null: false
    t.boolean "hide_advertisements", default: false, null: false
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.datetime "last_renamed_at", default: "1970-01-01 00:00:00", null: false
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["current_filter_id"], name: "index_users_on_current_filter_id"
    t.index ["deleted_by_user_id"], name: "index_users_on_deleted_by_user_id", where: "(deleted_by_user_id IS NOT NULL)"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", unique: true
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "vpns", id: false, force: :cascade do |t|
    t.inet "ip", null: false
    t.index ["ip"], name: "index_vpns_on_ip", opclass: :inet_ops, using: :gist
  end

  add_foreign_key "badge_awards", "badges", on_update: :cascade, on_delete: :cascade
  add_foreign_key "badge_awards", "users", column: "awarded_by_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "badge_awards", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "channel_subscriptions", "channels", on_update: :cascade, on_delete: :cascade
  add_foreign_key "channel_subscriptions", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "channels", "tags", column: "associated_artist_tag_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "comments", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "comments", "users", column: "deleted_by_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "comments", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "commission_items", "commissions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "commission_items", "images", column: "example_image_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "commissions", "images", column: "sheet_image_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "commissions", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "conversations", "users", column: "from_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "conversations", "users", column: "to_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "dnp_entries", "tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "dnp_entries", "users", column: "modifying_user_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "dnp_entries", "users", column: "requesting_user_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "donations", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "duplicate_reports", "images", column: "duplicate_of_image_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "duplicate_reports", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "duplicate_reports", "users", column: "modifier_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "duplicate_reports", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "filters", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "fingerprint_bans", "users", column: "banning_user_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "forum_subscriptions", "forums", on_update: :cascade, on_delete: :cascade
  add_foreign_key "forum_subscriptions", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "forums", "posts", column: "last_post_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "forums", "topics", column: "last_topic_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "galleries", "images", column: "thumbnail_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "galleries", "users", column: "creator_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "gallery_interactions", "galleries", on_update: :cascade, on_delete: :cascade
  add_foreign_key "gallery_interactions", "images", on_update: :cascade, on_delete: :restrict
  add_foreign_key "gallery_subscriptions", "galleries", on_update: :cascade, on_delete: :cascade
  add_foreign_key "gallery_subscriptions", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "image_faves", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "image_faves", "users", on_update: :cascade, on_delete: :restrict
  add_foreign_key "image_features", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "image_features", "users", on_update: :cascade, on_delete: :restrict
  add_foreign_key "image_hides", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "image_hides", "users", on_update: :cascade, on_delete: :restrict
  add_foreign_key "image_intensities", "images"
  add_foreign_key "image_subscriptions", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "image_subscriptions", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "image_taggings", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "image_taggings", "tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "image_votes", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "image_votes", "users", on_update: :cascade, on_delete: :restrict
  add_foreign_key "images", "images", column: "duplicate_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "images", "users", column: "deleted_by_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "images", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "messages", "users", column: "from_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "mod_notes", "users", column: "moderator_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "poll_options", "polls", on_update: :cascade, on_delete: :cascade
  add_foreign_key "poll_votes", "poll_options", on_update: :cascade, on_delete: :cascade
  add_foreign_key "poll_votes", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "polls", "topics", on_update: :cascade, on_delete: :cascade
  add_foreign_key "polls", "users", column: "deleted_by_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "posts", "topics", on_update: :cascade, on_delete: :cascade
  add_foreign_key "posts", "users", column: "deleted_by_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "posts", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "reports", "users", column: "admin_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "reports", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "site_notices", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "source_changes", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "source_changes", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "static_page_versions", "static_pages", on_update: :cascade, on_delete: :restrict
  add_foreign_key "static_page_versions", "users", on_update: :cascade, on_delete: :restrict
  add_foreign_key "subnet_bans", "users", column: "banning_user_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "tag_changes", "images", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tag_changes", "tags", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tag_changes", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tags", "tags", column: "aliased_tag_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tags_implied_tags", "tags", column: "implied_tag_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tags_implied_tags", "tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "topic_subscriptions", "topics", on_update: :cascade, on_delete: :cascade
  add_foreign_key "topic_subscriptions", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "topics", "forums", on_update: :cascade, on_delete: :cascade
  add_foreign_key "topics", "posts", column: "last_post_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "topics", "users", column: "deleted_by_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "topics", "users", column: "locked_by_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "topics", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "unread_notifications", "notifications", on_update: :cascade, on_delete: :cascade
  add_foreign_key "unread_notifications", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_bans", "users", column: "banning_user_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "user_bans", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_fingerprints", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_ips", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_links", "tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_links", "users", column: "contacted_by_user_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "user_links", "users", column: "verified_by_user_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "user_links", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_name_changes", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_statistics", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_whitelists", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users", "filters", column: "current_filter_id", on_update: :cascade, on_delete: :restrict
  add_foreign_key "users", "users", column: "deleted_by_user_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "users_roles", "roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users_roles", "users", on_update: :cascade, on_delete: :cascade
end
