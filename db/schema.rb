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

ActiveRecord::Schema[8.0].define(version: 2025_11_12_170000) do
  create_table "items", force: :cascade do |t|
    t.string "name"
    t.integer "quantity"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "workspace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_items_on_slug", unique: true
    t.index ["workspace_id"], name: "index_items_on_workspace_id"
  end

  create_table "missing_reports", force: :cascade do |t|
    t.integer "reservation_id"
    t.integer "item_id"
    t.integer "workspace_id"
    t.integer "quantity"
    t.boolean "resolved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.datetime "reported_at"
    t.index ["item_id"], name: "index_missing_reports_on_item_id"
    t.index ["reservation_id"], name: "index_missing_reports_on_reservation_id"
    t.index ["workspace_id"], name: "index_missing_reports_on_workspace_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id"
    t.text "message"
    t.boolean "read", default: false, null: false
    t.integer "reservation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_id"], name: "index_notifications_on_reservation_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "penalties", force: :cascade do |t|
    t.integer "user_id"
    t.string "reason"
    t.datetime "expires_at"
    t.integer "reservation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "workspace_id"
    t.index ["reservation_id"], name: "index_penalties_on_reservation_id"
    t.index ["user_id"], name: "index_penalties_on_user_id"
    t.index ["workspace_id"], name: "index_penalties_on_workspace_id"
  end

  create_table "reservations", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "user_id"
    t.integer "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity", default: 1, null: false
    t.boolean "no_show", default: false, null: false
    t.integer "returned_count", default: 0, null: false
    t.boolean "stock_adjusted", default: false, null: false
    t.boolean "in_cart", default: false, null: false
    t.datetime "hold_expires_at"
    t.index ["item_id", "in_cart", "hold_expires_at"], name: "idx_res_item_cart_exp"
    t.index ["item_id"], name: "index_reservations_on_item_id"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "user_to_workspaces", force: :cascade do |t|
    t.integer "user_id"
    t.integer "workspace_id"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_to_workspaces_on_user_id"
    t.index ["workspace_id"], name: "index_user_to_workspaces_on_workspace_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.string "verification_code"
    t.datetime "verification_sent_at"
    t.datetime "email_verified_at"
    t.string "reset_token"
    t.datetime "reset_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_workspaces_on_slug", unique: true
  end

  add_foreign_key "items", "workspaces"
  add_foreign_key "missing_reports", "items"
  add_foreign_key "missing_reports", "reservations"
  add_foreign_key "missing_reports", "workspaces"
  add_foreign_key "notifications", "reservations"
  add_foreign_key "notifications", "users"
  add_foreign_key "penalties", "reservations"
  add_foreign_key "penalties", "users"
  add_foreign_key "penalties", "workspaces"
  add_foreign_key "reservations", "items"
  add_foreign_key "reservations", "users"
  add_foreign_key "user_to_workspaces", "users"
  add_foreign_key "user_to_workspaces", "workspaces"
end
