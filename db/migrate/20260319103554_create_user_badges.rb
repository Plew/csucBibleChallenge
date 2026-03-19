class CreateUserBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true
      t.string :badge_key, null: false

      t.timestamps
    end

    add_index :user_badges, [ :user_id, :badge_key, :challenge_id ], unique: true
    add_index :user_badges, :badge_key
  end
end
