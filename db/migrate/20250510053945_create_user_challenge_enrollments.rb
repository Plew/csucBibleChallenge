class CreateUserChallengeEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :user_challenge_enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_challenge_enrollments, [ :user_id, :challenge_id ], unique: true, name: 'index_user_challenge_enrollments_on_user_and_challenge'
  end
end
