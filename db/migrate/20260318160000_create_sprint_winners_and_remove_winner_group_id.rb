class CreateSprintWinnersAndRemoveWinnerGroupId < ActiveRecord::Migration[8.1]
  def change
    create_table :sprint_winners do |t|
      t.references :sprint, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.integer :completion_percentage, null: false
      t.integer :on_schedule_percentage, null: false

      t.timestamps
    end

    add_index :sprint_winners, [ :sprint_id, :group_id ], unique: true

    remove_foreign_key :sprints, :groups, column: :winner_group_id
    remove_column :sprints, :winner_group_id, :integer
  end
end
