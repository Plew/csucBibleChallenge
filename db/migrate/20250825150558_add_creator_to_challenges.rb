class AddCreatorToChallenges < ActiveRecord::Migration[8.0]
  def change
    # First add the column as nullable
    add_reference :challenges, :creator, null: true, foreign_key: { to_table: :users }

    # Set existing challenges to be owned by the first admin user
    reversible do |direction|
      direction.up do
        admin_user = User.find_by(admin: true)
        if admin_user
          Challenge.update_all(creator_id: admin_user.id)
        end
      end
    end

    # Now make it non-nullable
    change_column_null :challenges, :creator_id, false
  end
end
