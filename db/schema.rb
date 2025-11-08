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

ActiveRecord::Schema[8.0].define(version: 2025_11_08_192710) do
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
  add_foreign_key "reservations", "items"
  add_foreign_key "reservations", "users"
  add_foreign_key "user_to_workspaces", "users"
  add_foreign_key "user_to_workspaces", "workspaces"
end
