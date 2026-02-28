class AddWinnerGroupToSprints < ActiveRecord::Migration[8.0]
  def change
    add_reference :sprints, :winner_group, foreign_key: { to_table: :groups }, null: true
  end
end
