class RenameStatWindowsToSprints < ActiveRecord::Migration[8.1]
  def change
    rename_table :stat_windows, :sprints
  end
end
