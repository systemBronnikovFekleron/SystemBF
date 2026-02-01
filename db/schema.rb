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

ActiveRecord::Schema[8.1].define(version: 2026_02_01_184807) do
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
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "featured", default: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.integer "price_kopecks", null: false
    t.string "product_type", null: false
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "updated_at", null: false
    t.index ["classification"], name: "index_users_on_classification"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "wallets", force: :cascade do |t|
    t.integer "balance_kopecks", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["balance_kopecks"], name: "index_wallets_on_balance_kopecks"
    t.index ["user_id"], name: "index_wallets_on_user_id"
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "product_accesses", "orders"
  add_foreign_key "product_accesses", "products"
  add_foreign_key "product_accesses", "users"
  add_foreign_key "products", "categories"
  add_foreign_key "profiles", "users"
  add_foreign_key "ratings", "users"
  add_foreign_key "wallets", "users"
end
