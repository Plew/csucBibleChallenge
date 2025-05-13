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

ActiveRecord::Schema[8.0].define(version: 2025_05_13_130000) do
  create_table "challenges", force: :cascade do |t|
    t.string "name"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "timezone"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.integer "challenge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "creator_id", null: false
    t.index ["challenge_id"], name: "index_groups_on_challenge_id"
    t.index ["creator_id"], name: "index_groups_on_creator_id"
  end

  create_table "readings", force: :cascade do |t|
    t.integer "challenge_id", null: false
    t.date "scheduled_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "book_number"
    t.integer "chapter_number"
    t.index ["challenge_id"], name: "index_readings_on_challenge_id"
  end

  create_table "user_challenge_enrollments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "challenge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_user_challenge_enrollments_on_challenge_id"
    t.index ["user_id", "challenge_id"], name: "index_user_challenge_enrollments_on_user_and_challenge", unique: true
    t.index ["user_id"], name: "index_user_challenge_enrollments_on_user_id"
  end

  create_table "user_group_enrollments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_user_group_enrollments_on_group_id"
    t.index ["user_id", "group_id"], name: "index_user_group_enrollments_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_user_group_enrollments_on_user_id"
  end

  create_table "user_readings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "reading_id", null: false
    t.date "completed_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reading_id"], name: "index_user_readings_on_reading_id"
    t.index ["user_id", "reading_id"], name: "index_user_readings_on_user_id_and_reading_id", unique: true
    t.index ["user_id"], name: "index_user_readings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "verses", force: :cascade do |t|
    t.string "version"
    t.integer "book_number"
    t.integer "chapter_number"
    t.integer "verse_number"
    t.text "verse_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_number"], name: "index_verses_on_book_number"
    t.index ["chapter_number"], name: "index_verses_on_chapter_number"
    t.index ["verse_number"], name: "index_verses_on_verse_number"
    t.index ["version"], name: "index_verses_on_version"
  end

  add_foreign_key "groups", "challenges"
  add_foreign_key "groups", "users", column: "creator_id"
  add_foreign_key "readings", "challenges"
  add_foreign_key "user_challenge_enrollments", "challenges"
  add_foreign_key "user_challenge_enrollments", "users"
  add_foreign_key "user_group_enrollments", "groups"
  add_foreign_key "user_group_enrollments", "users"
  add_foreign_key "user_readings", "readings"
  add_foreign_key "user_readings", "users"
end
