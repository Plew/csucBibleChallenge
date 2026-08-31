class EnsureOldTestamentVersesImported < ActiveRecord::Migration[8.1]
  def up
    # Enqueue background import so database migration finishes instantly (<0.01s)
    # and Puma container starts without healthcheck timeouts.
    ImportMissingVersesJob.perform_later
  end

  def down
  end
end
