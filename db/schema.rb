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

ActiveRecord::Schema[8.1].define(version: 2026_02_04_150855) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "email_templates", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.jsonb "available_variables", default: [], null: false
    t.text "body_html", null: false
    t.text "body_text"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "last_sent_at"
    t.string "name", null: false
    t.integer "sent_count", default: 0, null: false
    t.string "subject", null: false
    t.boolean "system_default", default: false, null: false
    t.string "template_key", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["active"], name: "index_email_templates_on_active"
    t.index ["category"], name: "index_email_templates_on_category"
    t.index ["template_key"], name: "index_email_templates_on_template_key", unique: true
  end

  create_table "integration_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error_details"
    t.string "event_type", null: false
    t.bigint "integration_setting_id", null: false
    t.text "message"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "related_id"
    t.string "related_type"
    t.string "status", null: false
    t.index ["event_type"], name: "index_integration_logs_on_event_type"
    t.index ["integration_setting_id", "status", "created_at"], name: "index_integration_logs_on_setting_status_created"
    t.index ["related_type", "related_id"], name: "index_integration_logs_on_related_type_and_related_id"
  end

  create_table "integration_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.boolean "enabled", default: false, null: false
    t.text "encrypted_credentials"
    t.string "integration_type", null: false
    t.datetime "last_test_at"
    t.text "last_test_message"
    t.string "last_test_status"
    t.datetime "last_used_at"
    t.string "name", null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.integer "usage_count", default: 0, null: false
    t.index ["enabled"], name: "index_integration_settings_on_enabled"
    t.index ["integration_type"], name: "index_integration_settings_on_integration_type", unique: true
  end

  create_table "integration_statistics", force: :cascade do |t|
    t.integer "avg_duration_ms"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "failed_requests", default: 0, null: false
    t.bigint "integration_setting_id", null: false
    t.string "period_type", null: false
    t.decimal "success_rate", precision: 5, scale: 2
    t.integer "successful_requests", default: 0, null: false
    t.integer "total_requests", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_integration_statistics_on_date"
    t.index ["integration_setting_id", "date", "period_type"], name: "index_integration_stats_on_setting_date_period", unique: true
  end

  create_table "interaction_histories", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "follow_up_date"
    t.datetime "interaction_date"
    t.integer "interaction_type"
    t.integer "status"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["admin_user_id"], name: "index_interaction_histories_on_admin_user_id"
    t.index ["user_id"], name: "index_interaction_histories_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.integer "price_kopecks", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "order_requests", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.jsonb "form_data", default: {}
    t.bigint "order_id"
    t.datetime "paid_at"
    t.string "payment_method"
    t.bigint "product_id", null: false
    t.datetime "rejected_at"
    t.text "rejection_reason"
    t.string "request_number", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_kopecks", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["approved_by_id"], name: "index_order_requests_on_approved_by_id"
    t.index ["created_at"], name: "index_order_requests_on_created_at"
    t.index ["order_id"], name: "index_order_requests_on_order_id"
    t.index ["product_id", "status"], name: "index_order_requests_on_product_id_and_status"
    t.index ["product_id"], name: "index_order_requests_on_product_id"
    t.index ["request_number"], name: "index_order_requests_on_request_number", unique: true
    t.index ["status"], name: "index_order_requests_on_status"
    t.index ["user_id", "status"], name: "index_order_requests_on_user_id_and_status"
    t.index ["user_id"], name: "index_order_requests_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "order_number", null: false
    t.datetime "paid_at"
    t.string "payment_id"
    t.string "payment_method"
    t.string "status", default: "pending", null: false
    t.integer "total_kopecks", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["paid_at"], name: "index_orders_on_paid_at"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "product_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["order_id"], name: "index_product_accesses_on_order_id"
    t.index ["product_id"], name: "index_product_accesses_on_product_id"
    t.index ["user_id", "product_id"], name: "index_product_accesses_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_product_accesses_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "auto_approve", default: false, null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "featured", default: false
    t.jsonb "form_fields", default: {}
    t.string "name", null: false
    t.integer "position", default: 0
    t.integer "price_kopecks", null: false
    t.string "product_type", null: false
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["auto_approve"], name: "index_products_on_auto_approve"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["product_type"], name: "index_products_on_product_type"
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["status"], name: "index_products_on_status"
  end

  create_table "profiles", force: :cascade do |t|
    t.text "bio"
    t.date "birth_date"
    t.string "city"
    t.string "country", default: "RU"
    t.datetime "created_at", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "level", default: 1, null: false
    t.integer "points", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["level"], name: "index_ratings_on_level"
    t.index ["points"], name: "index_ratings_on_points"
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "classification", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name"
    t.datetime "last_login_at"
    t.inet "last_login_ip"
    t.string "last_name"
    t.string "password_digest", null: false
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.bigint "telegram_chat_id"
    t.datetime "updated_at", null: false
    t.index ["classification"], name: "index_users_on_classification"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["telegram_chat_id"], name: "index_users_on_telegram_chat_id", unique: true
  end

  create_table "wallet_transactions", force: :cascade do |t|
    t.integer "amount_kopecks", null: false
    t.integer "balance_after_kopecks", null: false
    t.integer "balance_before_kopecks", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "external_id"
    t.bigint "order_request_id"
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "wallet_id", null: false
    t.index ["external_id"], name: "index_wallet_transactions_on_external_id"
    t.index ["order_request_id"], name: "index_wallet_transactions_on_order_request_id"
    t.index ["transaction_type"], name: "index_wallet_transactions_on_transaction_type"
    t.index ["wallet_id", "created_at"], name: "index_wallet_transactions_on_wallet_id_and_created_at"
    t.index ["wallet_id"], name: "index_wallet_transactions_on_wallet_id"
  end

  create_table "wallets", force: :cascade do |t|
    t.integer "balance_kopecks", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["balance_kopecks"], name: "index_wallets_on_balance_kopecks"
    t.index ["user_id"], name: "index_wallets_on_user_id"
  end

  add_foreign_key "interaction_histories", "users"
  add_foreign_key "interaction_histories", "users", column: "admin_user_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_requests", "orders"
  add_foreign_key "order_requests", "products"
  add_foreign_key "order_requests", "users"
  add_foreign_key "order_requests", "users", column: "approved_by_id"
  add_foreign_key "orders", "users"
  add_foreign_key "product_accesses", "orders"
  add_foreign_key "product_accesses", "products"
  add_foreign_key "product_accesses", "users"
  add_foreign_key "products", "categories"
  add_foreign_key "profiles", "users"
  add_foreign_key "ratings", "users"
  add_foreign_key "wallet_transactions", "order_requests"
  add_foreign_key "wallet_transactions", "wallets"
  add_foreign_key "wallets", "users"
end
