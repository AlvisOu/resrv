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

ActiveRecord::Schema[8.0].define(version: 2025_10_21_143431) do
  create_table "equipment", force: :cascade do |t|
    t.integer "workspace_id"
    t.string "name", null: false
    t.text "description"
    t.integer "quantity", default: 1, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id", "name"], name: "index_equipment_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_equipment_on_workspace_id"
  end

  create_table "movies", force: :cascade do |t|
    t.string "title"
    t.string "rating"
    t.text "description"
    t.datetime "release_date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "director"
  end

  create_table "reservations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "equipment_id", null: false
    t.datetime "start_at", null: false
    t.datetime "end_at", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", default: "pending", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipment_id", "start_at", "end_at"], name: "index_reservations_on_equipment_and_time"
    t.index ["equipment_id"], name: "index_reservations_on_equipment_id"
    t.index ["user_id", "start_at", "end_at"], name: "index_reservations_on_user_and_time"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "timezone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_workspaces_on_slug", unique: true
  end

  add_foreign_key "equipment", "workspaces"
  add_foreign_key "reservations", "equipment"
  add_foreign_key "reservations", "users"
end
