class AddCreatorIdToGroups < ActiveRecord::Migration[7.0]
  def up
    add_reference :groups, :creator, foreign_key: { to_table: :users }, null: true

    # Backfill: assign a random group member as creator for each group
    Group.reset_column_information
    Group.find_each do |group|
      user_id = group.user_challenge_enrollments.first&.user_id
      group.update_column(:creator_id, user_id) if user_id
    end

    change_column_null :groups, :creator_id, false
  end

  def down
    remove_reference :groups, :creator
  end
end 