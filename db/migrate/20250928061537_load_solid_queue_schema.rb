class LoadSolidQueueSchema < ActiveRecord::Migration[8.0]
  def up
    # Load SolidQueue schema if tables don't exist
    unless ActiveRecord::Base.connection.table_exists?('solid_queue_jobs')
      load Rails.root.join('db', 'queue_schema.rb')
    end
  end

  def down
    # Drop all SolidQueue tables
    %w[
      solid_queue_blocked_executions
      solid_queue_claimed_executions
      solid_queue_failed_executions
      solid_queue_ready_executions
      solid_queue_recurring_executions
      solid_queue_scheduled_executions
      solid_queue_jobs
      solid_queue_pauses
      solid_queue_processes
      solid_queue_recurring_tasks
      solid_queue_semaphores
    ].each do |table_name|
      drop_table table_name, if_exists: true
    end
  end
end
