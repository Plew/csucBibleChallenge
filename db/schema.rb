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

ActiveRecord::Schema[8.0].define(version: 2025_10_24_043927) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "challenges", force: :cascade do |t|
    t.string "name"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "timezone"
    t.integer "creator_id", null: false
    t.string "invitation_token"
    t.text "description"
    t.boolean "hidden", default: false, null: false
    t.index ["creator_id"], name: "index_challenges_on_creator_id"
    t.index ["invitation_token"], name: "index_challenges_on_invitation_token", unique: true
  end

  create_table "email_login_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "challenge_id", null: false
    t.integer "reading_id", null: false
    t.string "token", null: false
    t.datetime "clicked_at"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_email_login_tokens_on_challenge_id"
    t.index ["reading_id"], name: "index_email_login_tokens_on_reading_id"
    t.index ["token"], name: "index_email_login_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_email_login_tokens_on_user_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.integer "user_id"
    t.integer "category"
    t.string "subject"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "group_messages", force: :cascade do |t|
    t.integer "group_id", null: false
    t.integer "user_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_messages_on_group_id"
    t.index ["user_id"], name: "index_group_messages_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.integer "challenge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "creator_id", null: false
    t.boolean "closed_to_new_members", default: false, null: false
    t.text "motto"
    t.string "token"
    t.index ["challenge_id"], name: "index_groups_on_challenge_id"
    t.index ["creator_id"], name: "index_groups_on_creator_id"
    t.index ["token"], name: "index_groups_on_token", unique: true
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

  create_table "seven_day_lobbies", force: :cascade do |t|
    t.integer "challenge_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id", "user_id"], name: "index_seven_day_lobbies_on_challenge_id_and_user_id", unique: true
    t.index ["challenge_id"], name: "index_seven_day_lobbies_on_challenge_id"
    t.index ["user_id"], name: "index_seven_day_lobbies_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.boolean "admin", default: false, null: false
    t.string "version", default: "ESV"
    t.string "reset_digest"
    t.datetime "password_reset_sent_at"
    t.boolean "daily_email", default: true
    t.string "unsubscribe_digest"
    t.datetime "unsubscribe_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "verse_messages", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reading_id", null: false
    t.integer "verse_number", null: false
    t.index ["created_at"], name: "index_verse_messages_on_created_at"
    t.index ["reading_id", "verse_number"], name: "index_verse_messages_on_reading_id_and_verse_number"
    t.index ["reading_id"], name: "index_verse_messages_on_reading_id"
    t.index ["user_id"], name: "index_verse_messages_on_user_id"
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
    t.index ["version", "book_number", "chapter_number", "verse_number"], name: "index_verses_on_version_book_chapter_verse", unique: true
    t.index ["version"], name: "index_verses_on_version"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "challenges", "users", column: "creator_id"
  add_foreign_key "email_login_tokens", "challenges"
  add_foreign_key "email_login_tokens", "readings"
  add_foreign_key "email_login_tokens", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "group_messages", "groups"
  add_foreign_key "group_messages", "users"
  add_foreign_key "groups", "challenges"
  add_foreign_key "groups", "users", column: "creator_id"
  add_foreign_key "readings", "challenges"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "user_challenge_enrollments", "challenges"
  add_foreign_key "user_challenge_enrollments", "users"
  add_foreign_key "user_group_enrollments", "groups"
  add_foreign_key "user_group_enrollments", "users"
  add_foreign_key "user_readings", "readings"
  add_foreign_key "user_readings", "users"
  add_foreign_key "verse_messages", "readings"
  add_foreign_key "verse_messages", "users"
end
