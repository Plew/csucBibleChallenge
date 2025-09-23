class CreateSolidQueueTables < ActiveRecord::Migration[8.0]
  def change
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
      t.index [ "active_job_id" ], name: "index_solid_queue_jobs_on_active_job_id"
      t.index [ "class_name" ], name: "index_solid_queue_jobs_on_class_name"
      t.index [ "finished_at" ], name: "index_solid_queue_jobs_on_finished_at"
      t.index [ "queue_name", "finished_at" ], name: "index_solid_queue_jobs_for_filtering"
      t.index [ "scheduled_at", "finished_at" ], name: "index_solid_queue_jobs_for_alerting"
    end

    create_table "solid_queue_ready_executions", force: :cascade do |t|
      t.bigint "job_id", null: false
      t.string "queue_name", null: false
      t.integer "priority", default: 0, null: false
      t.datetime "created_at", null: false
      t.index [ "job_id" ], name: "index_solid_queue_ready_executions_on_job_id", unique: true
      t.index [ "priority", "job_id" ], name: "index_solid_queue_poll_all"
      t.index [ "queue_name", "priority", "job_id" ], name: "index_solid_queue_poll_by_queue"
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
      t.index [ "key" ], name: "index_solid_queue_recurring_tasks_on_key", unique: true
      t.index [ "static" ], name: "index_solid_queue_recurring_tasks_on_static"
    end

    add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  end
end
