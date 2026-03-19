class AddGroupNameToSprintWinnersAndMakeGroupOptional < ActiveRecord::Migration[8.1]
  def change
    add_column :sprint_winners, :group_name, :string

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE sprint_winners
          SET group_name = (SELECT name FROM groups WHERE groups.id = sprint_winners.group_id)
          WHERE group_id IS NOT NULL
        SQL
      end
    end

    change_column_null :sprint_winners, :group_id, true
  end
end
