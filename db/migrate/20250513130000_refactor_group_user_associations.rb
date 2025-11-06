class RefactorGroupUserAssociations < ActiveRecord::Migration[7.0]
  def change
    # Remove group_id from user_challenge_enrollments
    remove_column :user_challenge_enrollments, :group_id, :integer

    # Create user_group_enrollments join table
    create_table :user_group_enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.timestamps
    end

    add_index :user_group_enrollments, [ :user_id, :group_id ], unique: true
  end
end
