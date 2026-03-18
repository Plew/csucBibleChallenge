class AddRoleToUserChallengeEnrollments < ActiveRecord::Migration[8.0]
  def change
    add_column :user_challenge_enrollments, :role, :string, default: "member", null: false
  end
end
