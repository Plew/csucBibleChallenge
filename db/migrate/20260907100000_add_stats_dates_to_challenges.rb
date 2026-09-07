class AddStatsDatesToChallenges < ActiveRecord::Migration[7.2]
  def change
    add_column :challenges, :stats_start_date, :date
    add_column :challenges, :stats_end_date, :date
  end
end
