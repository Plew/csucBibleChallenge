class CreateUserBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_badges, [ :user_id, :badge_id, :challenge_id ], unique: true, name: "index_user_badges_on_user_badge_challenge"
  end
end
