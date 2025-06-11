# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_06_09_190315) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.string "username", null: false
    t.string "email", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "approved", default: false, null: false
    t.index ["approved"], name: "index_comments_on_approved"
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["post_id", "approved"], name: "idx_comments_post_approved"
    t.index ["post_id"], name: "index_comments_on_post_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pages", force: :cascade do |t|
    t.string "name"
    t.integer "unique_visits", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "post_tags", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "post_translations", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.string "locale", limit: 5, null: false
    t.string "title", null: false
    t.text "body"
    t.string "slug", null: false
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_post_translations_on_locale"
    t.index ["post_id", "locale"], name: "index_post_translations_on_post_id_and_locale", unique: true
    t.index ["post_id"], name: "index_post_translations_on_post_id"
    t.index ["published"], name: "index_post_translations_on_published"
    t.index ["slug"], name: "index_post_translations_on_slug", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.integer "unique_visits", default: 0
    t.boolean "draft", default: false, null: false
    t.index ["draft", "created_at"], name: "index_posts_on_draft_and_created_at", where: "(draft = false)"
    t.index ["slug"], name: "index_posts_on_slug"
  end

  create_table "site_healths", force: :cascade do |t|
    t.string "metric_type", null: false
    t.decimal "value", precision: 10, scale: 2, null: false
    t.text "metadata"
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checked_at"], name: "index_site_healths_on_checked_at"
    t.index ["metric_type", "checked_at"], name: "index_site_healths_on_metric_type_and_checked_at"
    t.index ["metric_type"], name: "index_site_healths_on_metric_type"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "unlock_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.integer "visitable_id"
    t.string "visitable_type"
    t.string "ip_address"
    t.string "user_agent"
    t.string "referer"
    t.datetime "viewed_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "action_type", default: 0
    t.string "session_id"
    t.index ["action_type"], name: "index_visits_on_action_type"
    t.index ["ip_address", "viewed_at"], name: "index_visits_on_ip_address_and_viewed_at"
    t.index ["ip_address"], name: "index_visits_on_ip_address"
    t.index ["user_agent"], name: "index_visits_on_user_agent"
    t.index ["viewed_at"], name: "index_visits_on_viewed_at"
    t.index ["visitable_id", "visitable_type"], name: "index_visits_on_visitable_id_and_visitable_type"
    t.index ["visitable_type", "visitable_id", "ip_address", "viewed_at"], name: "index_visits_on_unique_check"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
  add_foreign_key "post_translations", "posts"
end
