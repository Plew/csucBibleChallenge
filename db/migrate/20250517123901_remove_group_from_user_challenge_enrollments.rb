class RemoveGroupFromUserChallengeEnrollments < ActiveRecord::Migration[8.0]
  def change
    # Attempt to remove the foreign key if it exists and follows conventions
    if foreign_key_exists?(:user_challenge_enrollments, :groups)
      remove_foreign_key :user_challenge_enrollments, :groups
    end

    # Attempt to remove the column if it exists
    if column_exists?(:user_challenge_enrollments, :group_id)
      remove_column :user_challenge_enrollments, :group_id, :bigint # or :integer if that was the type
    end
  end
end
